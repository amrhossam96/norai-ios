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

    func process(batch: NoraiEventBatch) async -> NoraiEventBatch {
        let sessionID = await sessionManager.currentSessionID
        var processedBatch: NoraiEventBatch = batch
        let anonymousID = await identityManager.currentIdentity().anonymousID
        processedBatch.metaData["session_id"] = .string(sessionID.uuidString)
        processedBatch.metaData["anonymous_id"] = .string(anonymousID.uuidString)
        processedBatch.events = batch.events.map {
            var event = $0
            event.sessionID = sessionID
            return event
        }
        return processedBatch
    }
}


