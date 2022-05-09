//
//  LoggingService.swift
//  Jimo
//
//  Created by Xilin Liu on 5/7/22.
//

import Foundation

let logger = LoggingService.singleton

class LoggingService {
    static let singleton = LoggingService()

    private init() {}

    func log(_ message: String, priority: LogPriority = .info) {
        let logData = LogData(message: message, priority: priority)

        #if DEBUG
        DispatchQueue.main.async {
            NSLog("[" + priority.rawValue.uppercased() + "] " +
                message)
        }
        #else
        WebService.request(.log(data: logData), expectedStatus: .created)
        #endif
    }

    enum LogPriority: String, Encodable {
        case debug, info, warn, error, fatal
    }

    struct LogData: Encodable {
        let message: String
        let priority: LogPriority

        var parameterized: [String: Any] { ["message": message, "priority": priority.rawValue.uppercased()] }
    }
}
