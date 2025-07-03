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

    func log(_ event: NoraiEvent, level: LogLevel) {
        isLogCalled = true
    }
    
    func log(_ error: any Error, level: Norai.LogLevel) {
        isLogErrorCalled = true
    }
    
    func getCurrentLogLevel() -> LogLevel {
        isGetCurrentLogLevelCalled = true
        return currentLogLevel
    }
}
