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
        switch event.type {
        case .itemFocusStarted:
            return await handleFocusStarted(event: event)
            
        case .itemFocusEnded:
            return await handleFocusEnded(event: event)
            
        default:
            // Pass through other events unchanged
            return event
        }
    }
    
    // MARK: - Private Processing Methods
    
    private func handleFocusStarted(event: NoraiEvent) async -> NoraiEvent {
        // Store the started event for later combination
        if let itemId = event.context.itemId {
            let key = createKey(sessionId: event.sessionId, itemId: itemId)
            pendingStartEvents[key] = event
        }
        
        // Return a "suppressed" event (we'll use a special type to indicate it shouldn't be dispatched)
        var suppressedEvent = event
        suppressedEvent.type = .interaction // Temporary placeholder
        suppressedEvent.tags.append("suppressed")
        return suppressedEvent
    }
    
    private func handleFocusEnded(event: NoraiEvent) async -> NoraiEvent {
        guard let itemId = event.context.itemId,
              let sessionId = event.sessionId else {
            return event
        }
        
        let key = createKey(sessionId: sessionId, itemId: itemId)
        
        // Find the matching started event
        guard let startedEvent = pendingStartEvents[key] else {
            // No matching start event - return ended event as-is
            return event
        }
        
        // Remove from pending events
        pendingStartEvents.removeValue(forKey: key)
        
        // Create a combined "item_viewed" event
        return createCombinedEvent(startedEvent: startedEvent, endedEvent: event)
    }
    
    private func createCombinedEvent(startedEvent: NoraiEvent, endedEvent: NoraiEvent) -> NoraiEvent {
        // Create comprehensive context with timing information
        let combinedContext = EventContext(
            screen: startedEvent.context.screen,
            component: startedEvent.context.component,
            itemId: startedEvent.context.itemId,
            visibilityRatio: startedEvent.context.visibilityRatio, // Peak visibility
            viewDuration: endedEvent.context.viewDuration,
            position: startedEvent.context.position,
            totalItems: startedEvent.context.totalItems
        )
        
        // Combine tags and dependencies
        let combinedTags = Array(Set(startedEvent.tags + endedEvent.tags + ["item_view", "processed"]))
        let combinedDependencies = startedEvent.dependencies + endedEvent.dependencies + [
            EventDependency(key: "focusStartTime", value: .string(startedEvent.timestamp?.iso8601String ?? "")),
            EventDependency(key: "focusEndTime", value: .string(endedEvent.timestamp?.iso8601String ?? ""))
        ]
        
        return NoraiEvent(
            id: UUID(),
            type: .itemViewed, // Clean, single event type
            timestamp: startedEvent.timestamp, // Use the start time as primary timestamp
            sessionId: startedEvent.sessionId,
            userId: startedEvent.userId,
            context: combinedContext,
            metadata: startedEvent.metadata, // Use start event metadata
            tags: combinedTags,
            dependencies: combinedDependencies
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