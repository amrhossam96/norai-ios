//
//  NoraiConfiguration.swift
//  Norai
//
//  Created by Amr on 28/06/2025.
//

import Foundation

public struct NoraiConfiguration: Sendable {
    let apiKey: String
    let environment: NoraiEnvironment
    let logLevel: LogLevel
    
    public init(apiKey: String, environment: NoraiEnvironment, logLevel: LogLevel = .debug) {
        self.apiKey = apiKey
        self.environment = environment
        self.logLevel = logLevel
    }
}
