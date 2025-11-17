//
//  ScreenContextEnricher.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import Foundation

struct ScreenContextEnricher: NoraiEventEnricherProtocol {
    init() {}
    
    func enrich(event: NoraiEvent) async -> NoraiEvent {
        var enrichedEvent = event
        
        return enrichedEvent
    }
} 
