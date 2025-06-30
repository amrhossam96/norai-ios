//
//  NoraiSession.swift
//  Norai
//
//  Created by Amr on 30/06/2025.
//

import Foundation

public struct NoraiSession: Sendable {
    public let sessionId: UUID
    public let startedAt: Date
    public var endedAt: Date?

    public init(sessionId: UUID = UUID(), startedAt: Date = Date(), endedAt: Date? = nil) {
        self.sessionId = sessionId
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
}