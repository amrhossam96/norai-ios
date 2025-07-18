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
    
    private func createEvent(
        _ eventName: String,
        itemId: String,
        sessionId: UUID = UUID(),
        viewDuration: Double? = nil,
        timestamp: Date = Date()
    ) -> NoraiEvent {
        var context: [String: String] = ["itemId": itemId]
        if let duration = viewDuration {
            context["viewDuration"] = String(duration)
        }
        
        return NoraiEvent(
            event: eventName,
            timestamp: timestamp,
            sessionId: sessionId,
            context: context
        )
    }
    
    @Test func shouldSuppressFocusStartedEvents() async {
        let processor = ViewDurationProcessor()
        let startEvent = createEvent("item_focus_started", itemId: "item-1")
        
        let result = await processor.process(events: [startEvent])
        
        #expect(result.count == 1)
        #expect(result.first?.tags.contains("suppressed") == true)
    }
    
    @Test func shouldPassThroughNonFocusEvents() async {
        let processor = ViewDurationProcessor()
        let normalEvent = createEvent("item_viewed", itemId: "item-1")
        
        let result = await processor.process(events: [normalEvent])
        
        #expect(result.count == 1)
        #expect(result.first?.event == "item_viewed")
        #expect(result.first?.tags.contains("suppressed") == false)
    }
    
    @Test func shouldCombineFocusStartAndEndEvents() async {
        let processor = ViewDurationProcessor()
        let sessionId = UUID()
        
        let startEvent = createEvent("item_focus_started", itemId: "item-1", sessionId: sessionId)
        let endEvent = createEvent("item_focus_ended", itemId: "item-1", sessionId: sessionId, viewDuration: 3.5)
        
        // Process start event (gets suppressed)
        _ = await processor.process(events: [startEvent])
        
        // Process end event (should create combined event)
        let result = await processor.process(events: [endEvent])
        
        #expect(result.count == 1)
        #expect(result.first?.event == "item_viewed")
        #expect(result.first?.context["viewDuration"] == "3.5")
    }
    
    @Test func shouldReturnFocusEndedEventWhenNoMatchingStart() async {
        let processor = ViewDurationProcessor()
        let endEvent = createEvent("item_focus_ended", itemId: "item-1", viewDuration: 2.0)
        
        let result = await processor.process(events: [endEvent])
        
        #expect(result.count == 1)
        #expect(result.first?.event == "item_focus_ended")
    }
    
    @Test func shouldGenerateUniqueIdsForCombinedEvents() async {
        let processor = ViewDurationProcessor()
        let sessionId = UUID()
        
        let startEvent = createEvent("item_focus_started", itemId: "item-1", sessionId: sessionId)
        let endEvent = createEvent("item_focus_ended", itemId: "item-1", sessionId: sessionId)
        
        _ = await processor.process(events: [startEvent])
        let result = await processor.process(events: [endEvent])
        
        let combinedEvent = result.first!
        #expect(combinedEvent.id != startEvent.id)
        #expect(combinedEvent.id != endEvent.id)
    }
    
    @Test func shouldUseStartEventTimestamp() async {
        let processor = ViewDurationProcessor()
        let sessionId = UUID()
        let startTime = Date(timeIntervalSince1970: 1000)
        let endTime = Date(timeIntervalSince1970: 1005)
        
        let startEvent = createEvent("item_focus_started", itemId: "item-1", sessionId: sessionId, timestamp: startTime)
        let endEvent = createEvent("item_focus_ended", itemId: "item-1", sessionId: sessionId, timestamp: endTime)
        
        _ = await processor.process(events: [startEvent])
        let result = await processor.process(events: [endEvent])
        
        let combinedEvent = result.first!
        #expect(combinedEvent.timestamp == startTime)
    }
    
    @Test func shouldCombineTagsFromBothEvents() async {
        let processor = ViewDurationProcessor()
        let sessionId = UUID()
        
        var startEvent = createEvent("item_focus_started", itemId: "item-1", sessionId: sessionId)
        startEvent.tags = ["start", "important"]
        
        var endEvent = createEvent("item_focus_ended", itemId: "item-1", sessionId: sessionId)
        endEvent.tags = ["end", "tracked"]
        
        _ = await processor.process(events: [startEvent])
        let result = await processor.process(events: [endEvent])
        
        let combinedEvent = result.first!
        #expect(combinedEvent.tags.contains("start"))
        #expect(combinedEvent.tags.contains("end"))
        #expect(combinedEvent.tags.contains("important"))
        #expect(combinedEvent.tags.contains("tracked"))
        #expect(combinedEvent.tags.contains("item_view"))
        #expect(combinedEvent.tags.contains("processed"))
    }
    
    @Test func shouldClearPendingEventAfterMatching() async {
        let processor = ViewDurationProcessor()
        let sessionId = UUID()
        
        let startEvent = createEvent("item_focus_started", itemId: "item-1", sessionId: sessionId)
        let endEvent1 = createEvent("item_focus_ended", itemId: "item-1", sessionId: sessionId)
        let endEvent2 = createEvent("item_focus_ended", itemId: "item-1", sessionId: sessionId)
        
        _ = await processor.process(events: [startEvent])
        let result1 = await processor.process(events: [endEvent1])
        let result2 = await processor.process(events: [endEvent2])
        
        // First end should create combined event
        #expect(result1.first?.event == "item_viewed")
        
        // Second end should pass through unchanged (no matching start)
        #expect(result2.first?.event == "item_focus_ended")
    }
    
    @Test func shouldHandleMultipleDifferentItems() async {
        let processor = ViewDurationProcessor()
        let sessionId = UUID()
        
        let start1 = createEvent("item_focus_started", itemId: "item-1", sessionId: sessionId)
        let start2 = createEvent("item_focus_started", itemId: "item-2", sessionId: sessionId)
        let end1 = createEvent("item_focus_ended", itemId: "item-1", sessionId: sessionId)
        let end2 = createEvent("item_focus_ended", itemId: "item-2", sessionId: sessionId)
        
        // Process all events
        _ = await processor.process(events: [start1, start2])
        let results = await processor.process(events: [end1, end2])
        
        let combinedEvents = results.filter { $0.event == "item_viewed" }
        #expect(combinedEvents.count == 2)
        
        let item1Event = combinedEvents.first { $0.context["itemId"] == "item-1" }
        #expect(item1Event != nil)
        
        let item2Event = combinedEvents.first { $0.context["itemId"] == "item-2" }
        #expect(item2Event != nil)
    }
    
    @Test func shouldHandleSameItemAcrossDifferentSessions() async {
        let processor = ViewDurationProcessor()
        let session1 = UUID()
        let session2 = UUID()
        
        let start1 = createEvent("item_focus_started", itemId: "item-1", sessionId: session1)
        let start2 = createEvent("item_focus_started", itemId: "item-1", sessionId: session2)
        let end1 = createEvent("item_focus_ended", itemId: "item-1", sessionId: session1)
        let end2 = createEvent("item_focus_ended", itemId: "item-1", sessionId: session2)
        
        _ = await processor.process(events: [start1, start2])
        let results = await processor.process(events: [end1, end2])
        
        let combinedEvents = results.filter { $0.event == "item_viewed" }
        #expect(combinedEvents.count == 2)
        
        let session1Event = combinedEvents.first { $0.sessionId == session1 }
        let session2Event = combinedEvents.first { $0.sessionId == session2 }
        
        #expect(session1Event != nil)
        #expect(session2Event != nil)
    }
    
    @Test func shouldHandleEventsWithoutItemId() async {
        let processor = ViewDurationProcessor()
        
        // Event without itemId should pass through unchanged
        let eventWithoutItemId = NoraiEvent(
            event: "item_focus_started",
            context: [:] // No itemId
        )
        
        let result = await processor.process(events: [eventWithoutItemId])
        
        #expect(result.count == 1)
        #expect(result.first?.event == "interaction")
        #expect(result.first?.tags.contains("suppressed") == true)
    }
    
    @Test func shouldHandleEventsWithoutSessionId() async {
        let processor = ViewDurationProcessor()
        
        let eventWithoutSession = NoraiEvent(
            event: "item_focus_ended",
            sessionId: nil,
            context: ["itemId": "item-1"]
        )
        
        let result = await processor.process(events: [eventWithoutSession])
        
        #expect(result.count == 1)
        #expect(result.first?.event == "item_focus_ended")
    }
    
    @Test func shouldHandleMixedEventTypes() async {
        let processor = ViewDurationProcessor()
        
        let mixedEvents = [
            createEvent("screen_viewed", itemId: ""),
            createEvent("item_focus_started", itemId: "item-1"),
            createEvent("interaction", itemId: ""),
            createEvent("item_viewed", itemId: "item-2")
        ]
        
        let result = await processor.process(events: mixedEvents)
        
        #expect(result.count == 4)
        
        // Only focus_started should be suppressed
        let suppressedEvents = result.filter { $0.tags.contains("suppressed") }
        #expect(suppressedEvents.count == 1)
        #expect(suppressedEvents.first?.event == "interaction")
    }
    
    @Test func shouldMaintainPendingStateAcrossProcessCalls() async {
        let processor = ViewDurationProcessor()
        let sessionId = UUID()
        
        // Process start event in first call
        let startEvent = createEvent("item_focus_started", itemId: "item-1", sessionId: sessionId)
        let result1 = await processor.process(events: [startEvent])
        #expect(result1.first?.tags.contains("suppressed") == true)
        
        // Process some other events
        let otherEvents = [
            createEvent("screen_viewed", itemId: ""),
            createEvent("interaction", itemId: "")
        ]
        let result2 = await processor.process(events: otherEvents)
        #expect(result2.count == 2)
        
        // Process end event - should still find the pending start
        let endEvent = createEvent("item_focus_ended", itemId: "item-1", sessionId: sessionId)
        let result3 = await processor.process(events: [endEvent])
        
        #expect(result3.first?.event == "item_viewed")
    }
    
    @Test func shouldHandleMultiplePendingEvents() async {
        let processor = ViewDurationProcessor()
        let sessionId = UUID()
        
        // Start tracking multiple items
        let item1Start = createEvent("item_focus_started", itemId: "item-1", sessionId: sessionId)
        let item2Start = createEvent("item_focus_started", itemId: "item-2", sessionId: sessionId)
        let item3Start = createEvent("item_focus_started", itemId: "item-3", sessionId: sessionId)
        
        _ = await processor.process(events: [item1Start, item2Start, item3Start])
        
        // End only item-2
        let item2End = createEvent("item_focus_ended", itemId: "item-2", sessionId: sessionId)
        let results = await processor.process(events: [item2End])
        
        #expect(results.count == 1)
        #expect(results.first?.event == "item_viewed")
        #expect(results.first?.context["itemId"] == "item-2")
        
        // Later end item-1 and item-3
        let item1End = createEvent("item_focus_ended", itemId: "item-1", sessionId: sessionId)
        let item3End = createEvent("item_focus_ended", itemId: "item-3", sessionId: sessionId)
        let laterResults = await processor.process(events: [item1End, item3End])
        
        let item1 = laterResults.first { $0.context["itemId"] == "item-1" }
        let item2 = laterResults.first { $0.context["itemId"] == "item-2" }
        let item3 = laterResults.first { $0.context["itemId"] == "item-3" }
        
        #expect(item1?.event == "item_viewed")
        #expect(item3?.event == "item_viewed")
        #expect(item2 == nil) // item-2 was already processed
    }
    
    @Test func shouldHandleConcurrentProcessing() async {
        let processor = ViewDurationProcessor()
        let sessionId = UUID()
        
        await withTaskGroup(of: [NoraiEvent].self) { group in
            // Process start events concurrently
            for i in 1...10 {
                group.addTask {
                    let startEvent = createEvent("item_focus_started", itemId: "item-\(i)", sessionId: sessionId)
                    return await processor.process(events: [startEvent])
                }
            }
            
            // Collect results (should all be suppressed)
            var allResults: [NoraiEvent] = []
            for await results in group {
                allResults.append(contentsOf: results)
            }
            
            #expect(allResults.count == 10)
            #expect(allResults.allSatisfy { $0.tags.contains("suppressed") })
        }
        
        // Now process end events concurrently
        await withTaskGroup(of: [NoraiEvent].self) { group in
            for i in 1...10 {
                group.addTask {
                    let endEvent = createEvent("item_focus_ended", itemId: "item-\(i)", sessionId: sessionId)
                    return await processor.process(events: [endEvent])
                }
            }
            
            var combinedResults: [NoraiEvent] = []
            for await results in group {
                combinedResults.append(contentsOf: results)
            }
            
            // Should have combined all events
            let combinedEvents = combinedResults.filter { $0.event == "item_viewed" }
            #expect(combinedEvents.count == 10)
        }
    }
} 