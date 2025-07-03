//
//  NoraiLoggerProtocol.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation

public protocol NoraiLoggerProtocol: Sendable {
    func log(_ event: NoraiEvent, level: LogLevel) async
    func log(_ error: any Error, level: LogLevel) async
    func getCurrentLogLevel() async -> LogLevel
}
