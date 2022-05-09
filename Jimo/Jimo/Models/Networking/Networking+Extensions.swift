//
//  Networking+Extensions.swift
//  Jimo
//
//  Created by Xilin Liu on 5/7/22.
//

import Foundation

// TODO log all these nulls
extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
    var data: Data? { try? JSONSerialization.data(withJSONObject: self, options: []) }
    var dataOrEmpty: Data { data ?? Data() }
}

extension Data {
    var dictionary: [String: Any]? {
        try? JSONSerialization.jsonObject(with: self, options: []) as? [String: Any]
    }

    var string: String? { String(data: self, encoding: .utf8) }
}

extension Encodable {
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder.jmEncoder.encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }

    var data: Data? { try? JSONEncoder.jmEncoder.encode(self) }
    var dataOrEmpty: Data { data ?? Data() }
}

extension JSONEncoder {
    static var jmEncoder: JSONEncoder {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }
}

extension Formatter {
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    static let iso8601noFS = ISO8601DateFormatter()
}

extension JSONDecoder.DateDecodingStrategy {
    static let customISO8601 = custom { decoder throws -> Date in
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        if let date = Formatter.iso8601.date(from: string) ?? Formatter.iso8601noFS.date(from: string) {
            return date
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
    }
}

extension JSONDecoder {
    private struct EmptyResponse: Encodable {}

    static func jmDecode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let realData = data.isEmpty ? try JSONEncoder().encode(EmptyResponse()) : data
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .customISO8601
        return try decoder.decode(type, from: realData)
    }
}

enum HttpStatus: Int, Equatable {
    case clientError = -1
    case decodingError = -2

    case ok = 200
    case created = 201
    case noContent = 204

    case badRequest = 400
    case unauthorized = 401
    case forbidden = 403
    case notFound = 404
    case conflict = 409

    case internalServerError = 500

    static func == (lhs: Int, rhs: HttpStatus) -> Bool {
        return lhs == rhs.rawValue
    }
}
