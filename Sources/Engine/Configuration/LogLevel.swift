//
//  LogLevel.swift
//  Norai
//
//  Created by Amr on 28/06/2025.
//

import Foundation

public enum LogLevel: Int, Comparable, Sendable, CaseIterable {
    case debug
    case info
    case warning
    case error

    public var description: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        }
    }

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
