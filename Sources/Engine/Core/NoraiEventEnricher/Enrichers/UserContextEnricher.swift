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
            enrichedEvent.metaData["user.firstName"] = .string(state.userContext?.firstName ?? "")
            enrichedEvent.metaData["user.lastName"] = .string(state.userContext?.lastName ?? "")
            enrichedEvent.metaData["user.email"] = .string(state.userContext?.email ?? "")
            enrichedEvent.metaData["user.id"] = .string(state.userContext?.id ?? "")
            enrichedEvent.metaData["user.isLoggedIn"] = .bool(state.userContext?.isLoggedIn ?? false)
            enrichedEvent.metaData["user.anonymousId"] = .string(state.userContext?.anonymousId ?? "")
            return enrichedEvent
        }
}
