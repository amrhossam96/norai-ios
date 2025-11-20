//
//  SessionEnricher.swift
//  Norai
//
//  Created by Amr Hossam on 20/11/2025.
//

import Foundation

struct SessionEnricher: NoraiEventEnricherProtocol {
    private let sessionManager: NoraiSessionManagerProtocol
    
    init(sessionManager: NoraiSessionManagerProtocol) {
        self.sessionManager = sessionManager
    }

    func enrich(event: NoraiEvent) async -> NoraiEvent {
        var enriched: NoraiEvent = event
        enriched.sessionID = await sessionManager.currentSessionID
        return enriched
    }
}

