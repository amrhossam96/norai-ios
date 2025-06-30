//
//  NoraiSessionManager.swift
//  Norai
//
//  Created by Amr on 30/06/2025.
//

import Foundation

public actor NoraiSessionManager {
    private var session: NoraiSession
    private var lastAcitivityTimestamp: Date
    private let sessionTimeout: TimeInterval = 30 * 60 
    public init() {
        self.session = NoraiSession(startedAt: .now)
        self.lastAcitivityTimestamp = .now
    }
}

extension NoraiSessionManager: NoraiSessionManagerProtocol {
    public func startSession() async {
        let now: Date = .now
        let timeSinceLastActivity: TimeInterval = now.timeIntervalSince(lastAcitivityTimestamp)
        if timeSinceLastActivity > sessionTimeout {
            session.endedAt = lastAcitivityTimestamp
            session = NoraiSession(startedAt: .now)
        }
        lastAcitivityTimestamp = now
    }

    public func endSession() async {
        session.endedAt = Date()
    }

    public func getCurrentSession() async -> NoraiSession {
        return session
    }
}