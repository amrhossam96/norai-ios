//
//  SessionProcessor.swift
//  Norai
//
//  Created by Amr Hossam on 20/11/2025.
//

import Foundation

struct SessionProcessor: NoraiEventProcessorProtocol {
    private let sessionManager: NoraiSessionManagerProtocol
    private let identityManager: NoraiIdentityManagerProtocol
    
    init(sessionManager: NoraiSessionManagerProtocol, identityManager: NoraiIdentityManagerProtocol) {
        self.sessionManager = sessionManager
        self.identityManager = identityManager
    }

    private func getLastActivityTime(from events: [NoraiEvent]) -> String {
        guard let latestEvent = events.max(by: { $0.createdAt < $1.createdAt }) else {
            return ""
        }
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: latestEvent.createdAt)
    }

    func process(batch: NoraiEventBatch) async -> NoraiEventBatch {
        let sessionID = await sessionManager.currentSessionID
        var processedBatch = batch
        let anonymousID = await identityManager.currentIdentity().anonymousID

        // Update metadata
        processedBatch.metaData["session_id"] = .string(sessionID.uuidString)
        processedBatch.metaData["anonymous_id"] = .string(anonymousID.uuidString)
        processedBatch.metaData["last_activity_at"] = .string(getLastActivityTime(from: batch.events))

        // Assign sessionID to all events
        processedBatch.events = batch.events.map { event in
            var e = event
            e.sessionID = sessionID
            return e
        }

        return processedBatch
    }

}


