//
//  ViewDurationProcessor.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import Foundation

actor ViewDurationProcessor: NoraiEventProcessorProtocol {
    private var pendingStartEvents: [String: NoraiEvent] = [:]
    
    init() {}
    
    func process(events: [NoraiEvent]) async -> [NoraiEvent] {
        var processedEvents: [NoraiEvent] = []
        for event in events {
            let processedEvent = await processEvent(event)
            processedEvents.append(processedEvent)
        }
        
        return processedEvents
    }
    
    private func processEvent(_ event: NoraiEvent) async -> NoraiEvent {
        NoraiEvent(
            eventType: "",
            anonymousID: UUID(),
            properties: [:],
            context: [:],
            metaData: [:]
        )
    }
}

