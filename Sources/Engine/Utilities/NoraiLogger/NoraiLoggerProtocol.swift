//
//  NoraiLoggerProtocol.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation

public protocol NoraiLoggerProtocol {
    func log(_ event: NoraiEvent, level: LogLevel)
    func log(_ error: any Error, level: LogLevel)
    func getCurrentLogLevel() -> LogLevel
}
