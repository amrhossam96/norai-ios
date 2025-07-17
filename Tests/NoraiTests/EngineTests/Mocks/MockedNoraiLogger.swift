//
//  MockedNoraiLogger.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation
import Norai

actor MockedNoraiLogger: NoraiLoggerProtocol {
    var isLogCalled: Bool = false
    var isLogErrorCalled: Bool = false
    var isGetCurrentLogLevelCalled: Bool = false
    var currentLogLevel: LogLevel = .none
    var isLogMessageCalled: Bool = false
    var isErrorLogged: Bool = false
    var logMessages: [String] = []
    var lastLogLevel: LogLevel?

    func log(_ event: NoraiEvent, level: LogLevel) {
        isLogCalled = true
        lastLogLevel = level
    }
    
    func log(_ error: any Error, level: LogLevel) {
        isLogErrorCalled = true
        isErrorLogged = true
        lastLogLevel = level
    }
    
    func getCurrentLogLevel() -> LogLevel {
        isGetCurrentLogLevelCalled = true
        return currentLogLevel
    }
    
    func log(_ message: String) async {
        isLogMessageCalled = true
        logMessages.append(message)
    }
    
    func reset() {
        isLogCalled = false
        isLogErrorCalled = false
        isGetCurrentLogLevelCalled = false
        isLogMessageCalled = false
        isErrorLogged = false
        logMessages = []
        lastLogLevel = nil
    }
}
