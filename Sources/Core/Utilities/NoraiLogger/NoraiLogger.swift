//
//  NoraiLogger.swift
//  Norai
//
//  Created by Amr on 28/06/2025.
//

import Foundation

public struct NoraiLogger: Sendable {
    private let minimumLevel: LogLevel
    
    public init(minimumLevel: LogLevel) {
        self.minimumLevel = minimumLevel
    }
    
    private func shouldLog(level: LogLevel) -> Bool {
        return level >= minimumLevel
    }
}

extension NoraiLogger: NoraiLoggerProtocol {
    public func log(_ error: any Error, level: LogLevel) {
        guard shouldLog(level: level) else { return }
        let loggedMessage: String = """
            [Norai] - \(level.description)]
            [Norai] - Error: \(error.localizedDescription)
            """
        print(loggedMessage)
    }
    
    public func log(_ message: String, level: LogLevel) {
        guard shouldLog(level: level) else { return }
        let loggedMessage: String = """
            [Norai] - \(level.description)]
            [Norai] - \(message)
            """
        print(loggedMessage)
    }
}




