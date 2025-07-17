//
//  ViewDurationProcessorTests.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import Foundation
@testable import Norai
import Testing

struct ViewDurationProcessorTests {
    
    // MARK: - Basic Processing Tests
    
    @Test func shouldPassThroughNonFocusEvents() async {
        let sut = ViewDurationProcessor()
        let events = [
            NoraiEvent(type: .screenViewed),
            NoraiEvent(type: .itemViewed),
            NoraiEvent(type: .interaction)
        ]
        
        let processedEvents = await sut.process(events: events)
        
        #expect(processedEvents.count == 3)
        #expect(processedEvents[0].type == .screenViewed)
        #expect(processedEvents[1].type == .itemViewed)
        #expect(processedEvents[2].type == .interaction)
    }
    
    @Test func shouldSuppressFocusStartedEvents() async {
        let sut = ViewDurationProcessor()
        let event = NoraiEvent(
            type: .itemFocusStarted,
            context: EventContext(itemId: "item-1")
        )
        
        let processedEvents = await sut.process(events: [event])
        
        #expect(processedEvents.count == 1)
        #expect(processedEvents[0].type == .interaction)
        #expect(processedEvents[0].tags.contains("suppressed"))
    }
    
    @Test func shouldReturnFocusEndedEventWhenNoMatchingStart() async {
        let sut = ViewDurationProcessor()
        let event = NoraiEvent(
            type: .itemFocusEnded,
            context: EventContext(itemId: "item-1", viewDuration: 2.5)
        )
        
        let processedEvents = await sut.process(events: [event])
        
        #expect(processedEvents.count == 1)
        #expect(processedEvents[0].type == .itemFocusEnded)
        #expect(processedEvents[0].context.itemId == "item-1")
    }
    
    // MARK: - Focus Event Pairing Tests
    
    @Test func shouldCombineFocusStartAndEndEvents() async {
        let sut = ViewDurationProcessor()
        let sessionId = UUID()
        
        let startEvent = NoraiEvent(
            type: .itemFocusStarted,
            timestamp: Date(),
            sessionId: sessionId,
            context: EventContext(
                screen: "HomeScreen",
                component: "ProductCard",
                itemId: "product-123",
                visibilityRatio: 0.8,
                position: 2,
                totalItems: 10
            ),
            tags: ["impression"]
        )
        
        let endEvent = NoraiEvent(
            type: .itemFocusEnded,
            timestamp: Date().addingTimeInterval(3.0),
            sessionId: sessionId,
            context: EventContext(
                itemId: "product-123",
                viewDuration: 3.0
            )
        )
        
        let processedEvents = await sut.process(events: [startEvent, endEvent])
        
        #expect(processedEvents.count == 2)
        
        // First event should be suppressed start
        #expect(processedEvents[0].type == .interaction)
        #expect(processedEvents[0].tags.contains("suppressed"))
        
        // Second event should be combined item_viewed
        let combinedEvent = processedEvents[1]
        #expect(combinedEvent.type == .itemViewed)
        #expect(combinedEvent.sessionId == sessionId)
        #expect(combinedEvent.context.screen == "HomeScreen")
        #expect(combinedEvent.context.component == "ProductCard")
        #expect(combinedEvent.context.itemId == "product-123")
        #expect(combinedEvent.context.visibilityRatio == 0.8)
        #expect(combinedEvent.context.viewDuration == 3.0)
        #expect(combinedEvent.context.position == 2)
        #expect(combinedEvent.context.totalItems == 10)
        #expect(combinedEvent.tags.contains("impression"))
        #expect(combinedEvent.tags.contains("item_view"))
        #expect(combinedEvent.tags.contains("processed"))
    }
    
    @Test func shouldHandleMultipleDifferentItems() async {
        let sut = ViewDurationProcessor()
        let sessionId = UUID()
        
        let events = [
            // Item 1 - start
            NoraiEvent(type: .itemFocusStarted, sessionId: sessionId, context: EventContext(itemId: "item-1")),
            // Item 2 - start  
            NoraiEvent(type: .itemFocusStarted, sessionId: sessionId, context: EventContext(itemId: "item-2")),
            // Item 1 - end
            NoraiEvent(type: .itemFocusEnded, sessionId: sessionId, context: EventContext(itemId: "item-1", viewDuration: 2.0)),
            // Item 2 - end
            NoraiEvent(type: .itemFocusEnded, sessionId: sessionId, context: EventContext(itemId: "item-2", viewDuration: 1.5))
        ]
        
        let processedEvents = await sut.process(events: events)
        
        #expect(processedEvents.count == 4)
        
        // Check for combined events
        let combinedEvents = processedEvents.filter { $0.type == .itemViewed }
        #expect(combinedEvents.count == 2)
        
        let item1Event = combinedEvents.first { $0.context.itemId == "item-1" }!
        #expect(item1Event.context.viewDuration == 2.0)
        
        let item2Event = combinedEvents.first { $0.context.itemId == "item-2" }!
        #expect(item2Event.context.viewDuration == 1.5)
    }
    
    @Test func shouldHandleSameItemAcrossDifferentSessions() async {
        let sut = ViewDurationProcessor()
        let session1 = UUID()
        let session2 = UUID()
        
        let events = [
            // Session 1 - Item A
            NoraiEvent(type: .itemFocusStarted, sessionId: session1, context: EventContext(itemId: "item-a")),
            // Session 2 - Item A (different session)
            NoraiEvent(type: .itemFocusStarted, sessionId: session2, context: EventContext(itemId: "item-a")),
            // Session 1 - Item A end
            NoraiEvent(type: .itemFocusEnded, sessionId: session1, context: EventContext(itemId: "item-a", viewDuration: 2.0)),
            // Session 2 - Item A end
            NoraiEvent(type: .itemFocusEnded, sessionId: session2, context: EventContext(itemId: "item-a", viewDuration: 1.0))
        ]
        
        let processedEvents = await sut.process(events: events)
        
        let combinedEvents = processedEvents.filter { $0.type == .itemViewed }
        #expect(combinedEvents.count == 2)
        
        let session1Event = combinedEvents.first { $0.sessionId == session1 }!
        let session2Event = combinedEvents.first { $0.sessionId == session2 }!
        
        #expect(session1Event.context.viewDuration == 2.0)
        #expect(session2Event.context.viewDuration == 1.0)
    }
    
    // MARK: - State Management Tests
    
    @Test func shouldMaintainPendingStateAcrossProcessCalls() async {
        let sut = ViewDurationProcessor()
        let sessionId = UUID()
        
        // Process start event first
        let startEvent = NoraiEvent(
            type: .itemFocusStarted,
            sessionId: sessionId,
            context: EventContext(itemId: "item-1", visibilityRatio: 0.9)
        )
        
        let firstBatch = await sut.process(events: [startEvent])
        #expect(firstBatch.count == 1)
        #expect(firstBatch[0].tags.contains("suppressed"))
        
        // Process end event in second call
        let endEvent = NoraiEvent(
            type: .itemFocusEnded,
            sessionId: sessionId,
            context: EventContext(itemId: "item-1", viewDuration: 5.0)
        )
        
        let secondBatch = await sut.process(events: [endEvent])
        #expect(secondBatch.count == 1)
        #expect(secondBatch[0].type == .itemViewed)
        #expect(secondBatch[0].context.visibilityRatio == 0.9)
        #expect(secondBatch[0].context.viewDuration == 5.0)
    }
    
    @Test func shouldClearPendingEventAfterMatching() async {
        let sut = ViewDurationProcessor()
        let sessionId = UUID()
        
        // Start and end for item-1
        let events1 = [
            NoraiEvent(type: .itemFocusStarted, sessionId: sessionId, context: EventContext(itemId: "item-1")),
            NoraiEvent(type: .itemFocusEnded, sessionId: sessionId, context: EventContext(itemId: "item-1", viewDuration: 2.0))
        ]
        _ = await sut.process(events: events1)
        
        // Try to end item-1 again - should not find pending start
        let orphanEnd = NoraiEvent(
            type: .itemFocusEnded,
            sessionId: sessionId,
            context: EventContext(itemId: "item-1", viewDuration: 1.0)
        )
        
        let result = await sut.process(events: [orphanEnd])
        #expect(result.count == 1)
        #expect(result[0].type == .itemFocusEnded) // Not combined
    }
    
    @Test func shouldHandleMultiplePendingEvents() async {
        let sut = ViewDurationProcessor()
        let sessionId = UUID()
        
        // Start multiple items
        let startEvents = [
            NoraiEvent(type: .itemFocusStarted, sessionId: sessionId, context: EventContext(itemId: "item-1")),
            NoraiEvent(type: .itemFocusStarted, sessionId: sessionId, context: EventContext(itemId: "item-2")),
            NoraiEvent(type: .itemFocusStarted, sessionId: sessionId, context: EventContext(itemId: "item-3"))
        ]
        _ = await sut.process(events: startEvents)
        
        // End them in reverse order
        let endEvents = [
            NoraiEvent(type: .itemFocusEnded, sessionId: sessionId, context: EventContext(itemId: "item-3", viewDuration: 1.0)),
            NoraiEvent(type: .itemFocusEnded, sessionId: sessionId, context: EventContext(itemId: "item-1", viewDuration: 3.0)),
            NoraiEvent(type: .itemFocusEnded, sessionId: sessionId, context: EventContext(itemId: "item-2", viewDuration: 2.0))
        ]
        
        let results = await sut.process(events: endEvents)
        
        let combinedEvents = results.filter { $0.type == .itemViewed }
        #expect(combinedEvents.count == 3)
        
        let item1 = combinedEvents.first { $0.context.itemId == "item-1" }!
        let item2 = combinedEvents.first { $0.context.itemId == "item-2" }!
        let item3 = combinedEvents.first { $0.context.itemId == "item-3" }!
        
        #expect(item1.context.viewDuration == 3.0)
        #expect(item2.context.viewDuration == 2.0)
        #expect(item3.context.viewDuration == 1.0)
    }
    
    // MARK: - Event Enrichment Tests
    
    @Test func shouldCombineTagsFromBothEvents() async {
        let sut = ViewDurationProcessor()
        let sessionId = UUID()
        
        let startEvent = NoraiEvent(
            type: .itemFocusStarted,
            sessionId: sessionId,
            context: EventContext(itemId: "item-1"),
            tags: ["impression", "auto-tracked"]
        )
        
        let endEvent = NoraiEvent(
            type: .itemFocusEnded,
            sessionId: sessionId,
            context: EventContext(itemId: "item-1", viewDuration: 2.0),
            tags: ["user-action", "scroll-triggered"]
        )
        
        let results = await sut.process(events: [startEvent, endEvent])
        let combinedEvent = results.first { $0.type == .itemViewed }!
        
        #expect(combinedEvent.tags.contains("impression"))
        #expect(combinedEvent.tags.contains("auto-tracked"))
        #expect(combinedEvent.tags.contains("user-action"))
        #expect(combinedEvent.tags.contains("scroll-triggered"))
        #expect(combinedEvent.tags.contains("item_view"))
        #expect(combinedEvent.tags.contains("processed"))
    }
    
    @Test func shouldCombineDependenciesFromBothEvents() async {
        let sut = ViewDurationProcessor()
        let sessionId = UUID()
        
        let startEvent = NoraiEvent(
            type: .itemFocusStarted,
            timestamp: Date(),
            sessionId: sessionId,
            context: EventContext(itemId: "item-1"),
            dependencies: [
                EventDependency(key: "startContext", value: .string("home-feed"))
            ]
        )
        
        let endEvent = NoraiEvent(
            type: .itemFocusEnded,
            timestamp: Date().addingTimeInterval(3.0),
            sessionId: sessionId,
            context: EventContext(itemId: "item-1", viewDuration: 3.0),
            dependencies: [
                EventDependency(key: "endReason", value: .string("scroll-out"))
            ]
        )
        
        let results = await sut.process(events: [startEvent, endEvent])
        let combinedEvent = results.first { $0.type == .itemViewed }!
        
        #expect(combinedEvent.dependencies.count >= 4) // 2 original + 2 timestamp deps
        
        let hasStartContext = combinedEvent.dependencies.contains { $0.key == "startContext" }
        let hasEndReason = combinedEvent.dependencies.contains { $0.key == "endReason" }
        let hasFocusStartTime = combinedEvent.dependencies.contains { $0.key == "focusStartTime" }
        let hasFocusEndTime = combinedEvent.dependencies.contains { $0.key == "focusEndTime" }
        
        #expect(hasStartContext)
        #expect(hasEndReason)
        #expect(hasFocusStartTime)
        #expect(hasFocusEndTime)
    }
    
    @Test func shouldUseStartEventTimestamp() async {
        let sut = ViewDurationProcessor()
        let sessionId = UUID()
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(5.0)
        
        let startEvent = NoraiEvent(
            type: .itemFocusStarted,
            timestamp: startTime,
            sessionId: sessionId,
            context: EventContext(itemId: "item-1")
        )
        
        let endEvent = NoraiEvent(
            type: .itemFocusEnded,
            timestamp: endTime,
            sessionId: sessionId,
            context: EventContext(itemId: "item-1", viewDuration: 5.0)
        )
        
        let results = await sut.process(events: [startEvent, endEvent])
        let combinedEvent = results.first { $0.type == .itemViewed }!
        
        #expect(combinedEvent.timestamp == startTime)
    }
    
    // MARK: - Edge Cases
    
    @Test func shouldHandleEventsWithoutItemId() async {
        let sut = ViewDurationProcessor()
        
        let startEvent = NoraiEvent(
            type: .itemFocusStarted,
            context: EventContext(screen: "HomeScreen") // No itemId
        )
        
        let results = await sut.process(events: [startEvent])
        
        #expect(results.count == 1)
        #expect(results[0].type == .interaction)
        #expect(results[0].tags.contains("suppressed"))
    }
    
    @Test func shouldHandleEventsWithoutSessionId() async {
        let sut = ViewDurationProcessor()
        
        let events = [
            NoraiEvent(type: .itemFocusStarted, context: EventContext(itemId: "item-1")),
            NoraiEvent(type: .itemFocusEnded, context: EventContext(itemId: "item-1", viewDuration: 2.0))
        ]
        
        let results = await sut.process(events: events)
        
        // Without session ID, events cannot be matched and combined
        #expect(results.count == 2)
        #expect(results[0].type == .interaction) // suppressed start
        #expect(results[0].tags.contains("suppressed"))
        #expect(results[1].type == .itemFocusEnded) // unmatched end
        #expect(results[1].context.itemId == "item-1")
    }
    
    @Test func shouldHandleMixedEventTypes() async {
        let sut = ViewDurationProcessor()
        let sessionId = UUID()
        
        let events = [
            NoraiEvent(type: .screenViewed, context: EventContext(screen: "Home")),
            NoraiEvent(type: .itemFocusStarted, sessionId: sessionId, context: EventContext(itemId: "item-1")),
            NoraiEvent(type: .interaction, context: EventContext(component: "Button")),
            NoraiEvent(type: .itemFocusEnded, sessionId: sessionId, context: EventContext(itemId: "item-1", viewDuration: 1.0)),
            NoraiEvent(type: .itemViewed, context: EventContext(itemId: "item-2"))
        ]
        
        let results = await sut.process(events: events)
        
        #expect(results.count == 5)
        
        // Non-focus events should pass through unchanged
        #expect(results[0].type == .screenViewed)
        #expect(results[2].type == .interaction)
        #expect(results[4].type == .itemViewed)
        
        // Focus events should be processed
        #expect(results[1].type == .interaction) // suppressed start
        #expect(results[3].type == .itemViewed) // combined event
    }
    
    @Test func shouldGenerateUniqueIdsForCombinedEvents() async {
        let sut = ViewDurationProcessor()
        let sessionId = UUID()
        
        let events = [
            NoraiEvent(type: .itemFocusStarted, sessionId: sessionId, context: EventContext(itemId: "item-1")),
            NoraiEvent(type: .itemFocusStarted, sessionId: sessionId, context: EventContext(itemId: "item-2")),
            NoraiEvent(type: .itemFocusEnded, sessionId: sessionId, context: EventContext(itemId: "item-1", viewDuration: 1.0)),
            NoraiEvent(type: .itemFocusEnded, sessionId: sessionId, context: EventContext(itemId: "item-2", viewDuration: 2.0))
        ]
        
        let results = await sut.process(events: events)
        let combinedEvents = results.filter { $0.type == .itemViewed }
        
        #expect(combinedEvents.count == 2)
        #expect(combinedEvents[0].id != combinedEvents[1].id)
    }
    
    // MARK: - Concurrency Tests
    
    @Test func shouldHandleConcurrentProcessing() async {
        let sut = ViewDurationProcessor()
        let sessionId = UUID()
        
        await withTaskGroup(of: Void.self) { group in
            // Multiple concurrent processing tasks
            for i in 0..<5 {
                group.addTask {
                    let events = [
                        NoraiEvent(type: .itemFocusStarted, sessionId: sessionId, context: EventContext(itemId: "item-\(i)")),
                        NoraiEvent(type: .itemFocusEnded, sessionId: sessionId, context: EventContext(itemId: "item-\(i)", viewDuration: Double(i)))
                    ]
                    _ = await sut.process(events: events)
                }
            }
        }
        
        // Should complete without data corruption or crashes
        let testEvent = NoraiEvent(type: .screenViewed)
        let result = await sut.process(events: [testEvent])
        #expect(result.count == 1)
        #expect(result[0].type == .screenViewed)
    }
} 