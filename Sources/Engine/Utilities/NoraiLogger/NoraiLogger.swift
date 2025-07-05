//
//  NoraiLogger.swift
//  Norai
//
//  Created by Amr on 28/06/2025.
//

import Foundation

public struct NoraiLogger {
    private var currentLevel: LogLevel
    
    public init(currentLevel: LogLevel) {
        self.currentLevel = currentLevel
    }
}

extension NoraiLogger: NoraiLoggerProtocol {
    public func log(_ event: NoraiEvent, level: LogLevel) {
        guard level >= currentLevel else { return }
        print("[Norai - \(level.description)] - Event Type: \(event.type.rawValue)\n[Norai - \(level.description)] - Timestamp: \(event.timestamp ?? .now)")
    }
    
    public func getCurrentLogLevel() -> LogLevel {
        return currentLevel
    }
    
    public func log(_ error: any Error, level: LogLevel) {
        print("[Norai - \(level.description)] - Error: \(error.localizedDescription)")
    }
    
    public func log(_ message: String) async {
        print("[Norai - \(currentLevel.description)]: \(message)")
    }
}
