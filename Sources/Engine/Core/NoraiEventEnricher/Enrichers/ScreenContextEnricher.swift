//
//  ScreenContextEnricher.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import Foundation

public struct ScreenContextEnricher: NoraiEventEnricherProtocol {
    public init() {}
    
    public func enrich(event: NoraiEvent, with state: NoraiEngineState) async -> NoraiEvent {
        var enrichedEvent = event
        
        // Add screen information from engine state
        enrichedEvent.context.screen = state.lastScreen
        
        // Add session context
        enrichedEvent.sessionId = state.sessionId
        
        return enrichedEvent
    }
} 