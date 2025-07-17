//
//  TimestampEnricher.swift
//  Norai
//
//  Created by Amr on 28/06/2025.
//

import Foundation

public struct TimestampEnricher: NoraiEventEnricherProtocol {
    public init() {}
    
    public func enrich(event: NoraiEvent, with state: NoraiEngineState) async -> NoraiEvent {
        var enrichedEvent = event
        
        // Set timestamp to current time when event is fresh (not when processed later)
        if enrichedEvent.timestamp == nil {
            enrichedEvent.timestamp = Date()
        }
        
        return enrichedEvent
    }
} 