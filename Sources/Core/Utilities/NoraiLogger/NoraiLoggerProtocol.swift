//
//  NoraiLoggerProtocol.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation

public protocol NoraiLoggerProtocol: Sendable {
    func log(_ error: any Error, level: LogLevel)
    func log(_ message: String, level: LogLevel)
}




