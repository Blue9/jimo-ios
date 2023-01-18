//
//  ImageUploadService.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/23/21.
//

import Foundation
import Combine

class ImageUploadService {

    /// Upload the image to the given URL with content type `image/jpeg`, field name `file`, and file name `upload.jpg`.
    static func uploadImage(url: URL, imageData: Data, token: String) -> URLSession.DataTaskPublisher {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        body.append(toData("--\(boundary)\r\n"))
        body.append(toData("Content-Disposition: form-data; name=\"file\"; filename=\"upload.jpg\"\r\n"))
        body.append(toData("Content-Type: image/jpeg\r\n\r\n"))
        body.append(imageData)
        body.append(toData("\r\n--\(boundary)--"))
        request.httpBody = body
        return URLSession.shared.dataTaskPublisher(for: request)
    }
}

private func toData(_ s: String) -> Data {
    s.data(using: .utf8)!
}
