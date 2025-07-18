//
//  UserContextEnricher.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation

public struct UserContextEnricher: NoraiEventEnricherProtocol {
    public init() {}
    public func enrich(event: NoraiEvent, with state: NoraiEngineState) async -> NoraiEvent {
            var enrichedEvent: NoraiEvent = event
            enrichedEvent.properties["user.firstName"] = state.userContext?.firstName ?? ""
            enrichedEvent.properties["user.lastName"] = state.userContext?.lastName ?? ""
            enrichedEvent.properties["user.email"] = state.userContext?.email ?? ""
            enrichedEvent.properties["user.id"] = state.userContext?.id ?? ""
            enrichedEvent.properties["user.isLoggedIn"] = String(state.userContext?.isLoggedIn ?? false)
            enrichedEvent.properties["user.anonymousId"] = state.userContext?.anonymousId ?? ""
            return enrichedEvent
        }
}
