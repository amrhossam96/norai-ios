//
//  LogLevelTests.swift
//  Norai
//
//  Created by Amr on 28/06/2025.
//

import Foundation
import Testing
import Norai

struct LogLevelTests {
    
    @Test func logLevelDebugIsSmallerThanInfo() {
        let logLevel: LogLevel = .debug
        #expect(logLevel < .info)
    }
    
    @Test func logLevelInfoIsSmallerThanWarning() {
        let logLevel: LogLevel = .info
        #expect(logLevel < .warning)
    }
    
    @Test func logLevelWarningIsSmallerThanError() {
        let logLevel: LogLevel = .warning
        #expect(logLevel < .error)
    }
    
    @Test func logLevelErrorIsSmallerThanNone() {
        let logLevel: LogLevel = .error
        #expect(logLevel < .none)
    }
    
    @Test func logLevelDebugMatchesDescriptionString() {
        let logLevel: LogLevel = .debug
        #expect(logLevel.description == "DEBUG")
    }
    
    @Test func logLevelInfoMatchesDescriptionString() {
        let logLevel: LogLevel = .info
        #expect(logLevel.description == "INFO")
    }
    
    @Test func logLevelWarningMatchesDescriptionString() {
        let logLevel: LogLevel = .warning
        #expect(logLevel.description == "WARNING")
    }
    
    @Test func logLevelErrorMatchesDescriptionString() {
        let logLevel: LogLevel = .error
        #expect(logLevel.description == "ERROR")
    }
    
    @Test func logLevelNoneMatchesDescriptionString() {
        let logLevel: LogLevel = .none
        #expect(logLevel.description == "NONE")
    }
}
