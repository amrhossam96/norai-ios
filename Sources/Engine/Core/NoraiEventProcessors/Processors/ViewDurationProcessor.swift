//
//  ViewDurationProcessor.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import Foundation

public actor ViewDurationProcessor: NoraiEventProcessorProtocol {
    private var pendingStartEvents: [String: NoraiEvent] = [:]
    
    public init() {}
    
    public func process(events: [NoraiEvent]) async -> [NoraiEvent] {
        var processedEvents: [NoraiEvent] = []
        
        // Process events sequentially to maintain state consistency
        for event in events {
            let processedEvent = await processEvent(event)
            processedEvents.append(processedEvent)
        }
        
        return processedEvents
    }
    
    private func processEvent(_ event: NoraiEvent) async -> NoraiEvent {
        // Handle focus events for item views
        switch event.event {
        case "item_focus_started":
            return await handleFocusStarted(event: event)
        case "item_focus_ended":
            return await handleFocusEnded(event: event)
        default:
            return event
        }
    }
    
    // MARK: - Private Processing Methods
    
    private func handleFocusStarted(event: NoraiEvent) async -> NoraiEvent {
        // Store the started event for later combination
        if let itemId = event.context["itemId"] {
            let key = createKey(sessionId: event.sessionId, itemId: itemId)
            pendingStartEvents[key] = event
        }
        
        // Return a "suppressed" event (we'll use a special type to indicate it shouldn't be dispatched)
        var suppressedEvent = event
        suppressedEvent.event = "interaction" // Temporary placeholder
        suppressedEvent.tags.append("suppressed")
        return suppressedEvent
    }
    
    private func handleFocusEnded(event: NoraiEvent) async -> NoraiEvent {
        guard let itemId = event.context["itemId"],
              let sessionId = event.sessionId else {
            return event
        }
        
        let key = createKey(sessionId: sessionId, itemId: itemId)
        
        guard let startedEvent = pendingStartEvents.removeValue(forKey: key) else {
            // No matching start event found, return the ended event as-is
            return event
        }
        
        // We have both start and end events, create a combined event
        return createCombinedEvent(startedEvent: startedEvent, endedEvent: event)
    }
    
    private func createCombinedEvent(startedEvent: NoraiEvent, endedEvent: NoraiEvent) -> NoraiEvent {
        // Create comprehensive context with timing information
        var combinedContext = startedEvent.context
        combinedContext["screen"] = startedEvent.context["screen"]
        combinedContext["component"] = startedEvent.context["component"]
        combinedContext["itemId"] = startedEvent.context["itemId"]
        combinedContext["viewDuration"] = endedEvent.context["viewDuration"]
        combinedContext["position"] = startedEvent.context["position"]
        combinedContext["totalItems"] = startedEvent.context["totalItems"]
        
        // Combine tags
        let combinedTags = Array(Set(startedEvent.tags + endedEvent.tags + ["item_view", "processed"]))
        
        return NoraiEvent(
            id: UUID(),
            event: "item_viewed", // Clean, single event type
            timestamp: startedEvent.timestamp, // Use the start time as primary timestamp
            sessionId: startedEvent.sessionId,
            userId: startedEvent.userId,
            context: combinedContext,
            metadata: startedEvent.metadata, // Use start event metadata
            tags: combinedTags
        )
    }
    
    private func createKey(sessionId: UUID?, itemId: String) -> String {
        return "\(sessionId?.uuidString ?? "unknown")_\(itemId)"
    }
}

// MARK: - Helper Extensions

extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
} 
