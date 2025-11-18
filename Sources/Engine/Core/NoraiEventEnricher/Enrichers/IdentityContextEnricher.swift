//
//  IdentityContextEnricher.swift
//  Norai
//
//  Created by Amr Hossam on 18/11/2025.
//

import Foundation

struct IdentityContextEnricher: Sendable, NoraiEventEnricherProtocol {
    let identityManager: NoraiIdentityManagerProtocol
    
    func enrich(event: NoraiEvent) async -> NoraiEvent {
        var enriched = event
        let identity = await identityManager.currentIdentity()
        enriched.anonymousID = identity.anonymousID
        enriched.userID = identity.userID
        return enriched
    }
}
