//
//  WebService.swift
//  Jimo
//
//  Created by Xilin Liu on 5/7/22.
//

import Foundation
import Moya

private enum RequestType: String { case stub, ngrok, local, staging, production, test }

enum WebService {
    private static var api: MoyaProvider<WebService> { [.stub, .test].contains(REQUEST_TYPE) ? MoyaProvider<WebService>(stubClosure: MoyaProvider.immediatelyStub) : MoyaProvider<WebService>(stubClosure: MoyaProvider.neverStub) }

    case getPost(postId: UUID)
    case followUser(userId: UUID)
}

extension WebService: TargetType {
    static func baseUrl() -> URL {
        let urlString: String
        switch REQUEST_TYPE {
        case .production: urlString = GC.productionBaseUrl
        case .staging: urlString = GC.stagingBaseUrl
        case .ngrok: urlString = GC.ngrokBaseUrl
        case .local: urlString = GC.localBaseUrl
        case .stub: urlString = GC.localBaseUrl
        case .test: urlString = GC.localBaseUrl
        }
        guard let url = URL(string: urlString) else {
            fatalError("baseURL could not be configured")
        }
        return url
    }

    var baseURL: URL {
        return WebService.baseUrl().appendingPathComponent("api/")
    }

    var path: String {
        switch self {
        case .getPost(let id): return "friends/\(id)/"
        case .followUser: return "follow/"
        }
    }

    var method: Moya.Method {
        switch self {
        case .followUser:
            return .post
        case .getPost:
            return .get
        }
    }

    var task: Task {
        let parameters: [String: Any]
        switch self {
        case .followUser(let userId):
            parameters = ["user_id": userId]
        }
        return .requestParameters(parameters: parameters, encoding: method == .get ? URLEncoding.queryString : JSONEncoding.default)
    }

    var headers: [String: String]? {
        var headers = ["Content-Type": "application/json"]
        switch self {
        case .login, .verification:
            break
        default:
            headers["Authorization"] = "Token \(Authentication.getToken() ?? "")"
        }
        return headers
    }

    /**
     Request function that either discards response or no content in response. This function calls the generic WebService request function and passes in
     an empty response to be decoded.

     - Parameters:
        - T: A Decodable struct for which the response body should be decoded into.
        - endpoint: The endpoint to request
        - retryCount: The number of retries to make before giving up. Set to -1 to retry indefinitely. Ignored for endpoints where `shouldRetry = false`.
            Default is 3.
        - expectedStatus: The HTTP status code the endpoint should receive. If the endpoint fails to return the given code, the `errorCallback`
            is triggered. If an endpoint is expected to return multiple statuses, handle additional status codes in the `errorCallback`.
        - errorCallback: If `completion` is not called, then `errorCallback` is fired. This may be due to a multitude of reasons, such as
             failed request, failed decoding, bad internet, incorrect `expectedStatus`, etc. Default functionality is to display an error popup with any
             messaging or failed status codes.
        - completion: The callback function after the endpoint has returned the correct status and the response body has been successfully
     */
    static func request(
        _ endpoint: WebService,
        retryCount: Int = 3,
        expectedStatus: HttpStatus = .ok,
        errorCallback: ((Int, Response?, Error?) -> Void)? = handleHttpFailure,
        completion: (() -> Void)? = nil
    ) {
        struct EmptyResponse: Decodable {}
        WebService.request(
            endpoint,
            retryCount: retryCount,
            expectedStatus: expectedStatus,
            errorCallback: errorCallback,
            completion: { (_: EmptyResponse) in completion?() }
        )
    }

    /**
     Generic function that makes the request.
     This is the only exposed function for the WebService.

     - Parameters:
        - endpoint: The endpoint to request
        - retryCount: The number of retries to make before giving up. Set to -1 to retry indefinitely. Ignored for endpoints where `shouldRetry = false`.
            Default is 3.
        - expectedStatus: The HTTP status code the endpoint should receive. If the endpoint fails to return the given code, the `errorCallback`
            is triggered. If an endpoint is expected to return multiple statuses, handle additional status codes in the `errorCallback`. Default is OK (200).
        - errorCallback: If `completion` is not called, then `errorCallback` is fired. This may be due to a multitude of reasons, such as
            failed request, failed decoding, bad internet, incorrect `expectedStatus`, etc. Default functionality is to display an error popup with any
            messaging or failed status codes.
        - completion: The callback function after the endpoint has returned the correct status and the response body has been successfully decoded.
        - T: A Decodable struct for which the response body should be decoded into.
     */
    static func request<T: Decodable>(
        _ endpoint: WebService,
        retryCount: Int = 3,
        expectedStatus: HttpStatus = .ok,
        errorCallback: ((Int, Response?, Error?) -> Void)? = handleHttpFailure,
        completion: ((T) -> Void)?
    ) {
        print(Date(), endpoint)
        let uuid = UUID()
        api.request(endpoint) { result in
            switch result {
            case .success(let response):
                print(Date(), endpoint, response.statusCode)
                do {
                    guard response.statusCode == expectedStatus.rawValue || [.stub, .test].contains(REQUEST_TYPE) else {
                        // cannot stub status codes
                        errorCallback?(response.statusCode, response, nil)
                        return
                    }
                    let obj = try JSONDecoder.jmDecode(T.self, from: response.data)
                    completion?(obj)
                } catch {
                    // mostly to catch decoding error
                    logEndpointFailure(endpoint: endpoint, message: error.localizedDescription)
                    errorCallback?(-1, nil, error)
                }
            case .failure(let e):
                if endpoint.shouldRetry && retryCount != 0 {
                    WebService.request(
                        endpoint,
                        retryCount: retryCount - 1,
                        expectedStatus: expectedStatus,
                        errorCallback: errorCallback,
                        completion: completion
                    )
                }

                logEndpointFailure(endpoint: endpoint, message: e.errorDescription ?? String(e.errorCode))
                errorCallback?(-1, nil, e)
            }
        }
    }

    /**
     Sends a log message to the backend, including the message and endpoint path, if the endpoint is not .log
     */
    private static func logEndpointFailure(endpoint: WebService, message: String) {
        switch endpoint {
        case log: break
        default: logger.log("\(endpoint.path) led to error: \(message)", priority: .warn)
        }
    }
}

// For debugging purposes, prints out the response json as string
extension Response {
    var printed: String? { String(data: data, encoding: .utf8) }
}
