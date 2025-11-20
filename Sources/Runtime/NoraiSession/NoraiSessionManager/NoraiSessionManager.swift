//
//  NoraiSessionManager.swift
//  Norai
//
//  Created by Amr Hossam on 20/11/2025.
//

import Foundation

actor NoraiSessionManager: Sendable, NoraiSessionManagerProtocol {

    private let idleTimeout: TimeInterval

    private var sessionID: UUID
    private var sessionStart: Date
    private var lastActivity: Date

    private let storage: FileSessionStorage

    init(idleTimeout: TimeInterval = 20 * 60, storage: FileSessionStorage) {
        self.idleTimeout = idleTimeout
        self.storage = storage

        let now = Date()
        if let storedID = storage.loadSessionID(),
           let storedStart = storage.loadSessionStart(),
           let storedLast = storage.loadLastActivity()
        {
            self.sessionID = UUID(uuidString: storedID) ?? UUID()
            self.sessionStart = storedStart
            self.lastActivity = storedLast
        } else {
            self.sessionID = UUID()
            self.sessionStart = now
            self.lastActivity = now
            Task {
                await storage.saveSessionID(sessionID.uuidString)
                await storage.saveSessionStart(now)
                await storage.saveLastActivity(now)
            }
        }
    }

    var currentSessionID: UUID { sessionID }

    func notifyActivity() async {
        let now = Date()
        lastActivity = now
        await storage.saveLastActivity(now)
        if now.timeIntervalSince(lastActivity) > idleTimeout {
            await rotateSession(reason: .idleTimeout)
        }
    }

    func appDidBecomeActive() async {
        await notifyActivity()
    }

    func appDidEnterBackground() async {
        let now = Date()
        if now.timeIntervalSince(lastActivity) > idleTimeout {
            await rotateSession(reason: .idleTimeout)
        }
    }

    func rotateSession(reason: SessionRotationReason) async {
        sessionID = UUID()
        sessionStart = Date()
        lastActivity = Date()
        await storage.saveSessionID(sessionID.uuidString)
        await storage.saveSessionStart(sessionStart)
        await storage.saveLastActivity(lastActivity)
    }
}
