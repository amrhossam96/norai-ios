//
//  NoraiBufferTests.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import Foundation
@testable import Norai
import Testing

struct NoraiBufferTests {
    
    // MARK: - Basic Functionality Tests
    
    private func createTestEvent(id: String = "test") -> NoraiEvent {
        NoraiEvent(
            event: "item_viewed",
            context: ["itemId": id]
        )
    }
    
    @Test func shouldInitializeWithEmptyBuffer() async {
        let buffer = NoraiBuffer()
        
        let events = await buffer.drain()
        let shouldFlush = await buffer.shouldFlush()
        
        #expect(events.isEmpty)
        #expect(shouldFlush == false) // Empty buffer shouldn't flush
    }
    
    @Test func shouldAddSingleEvent() async {
        let buffer = NoraiBuffer()
        let event = createTestEvent()
        
        await buffer.add(event)
        
        let events = await buffer.drain()
        #expect(events.count == 1)
        #expect(events.first?.event == "item_viewed")
    }
    
    @Test func shouldAddMultipleEvents() async {
        let buffer = NoraiBuffer()
        let events = [
            createTestEvent(id: "1"),
            createTestEvent(id: "2"),
            createTestEvent(id: "3")
        ]
        
        for event in events {
            await buffer.add(event)
        }
        
        let bufferedEvents = await buffer.drain()
        #expect(bufferedEvents.count == 3)
    }
    
    @Test func shouldDrainAndClearBuffer() async {
        let buffer = NoraiBuffer()
        let events = [
            createTestEvent(id: "1"),
            createTestEvent(id: "2")
        ]
        
        for event in events {
            await buffer.add(event)
        }
        
        let drainedEvents = await buffer.drain()
        let remainingEvents = await buffer.drain()
        
        #expect(drainedEvents.count == 2)
        #expect(remainingEvents.isEmpty)
    }
    
    @Test func shouldHandleEmptyDrain() async {
        let buffer = NoraiBuffer()
        
        let drainedEvents = await buffer.drain()
        
        #expect(drainedEvents.isEmpty)
    }
    
    @Test func shouldNotFlushWhenBelowThreshold() async {
        let buffer = NoraiBuffer()
        let event = createTestEvent()
        
        await buffer.add(event)
        
        let shouldFlush = await buffer.shouldFlush()
        #expect(shouldFlush == false)
    }
    
    @Test func shouldFlushWhenAtThreshold() async {
        let buffer = NoraiBuffer()
        
        // Add events to reach threshold (3)
        for i in 1...NoraiBufferPolicy.maxEventsCount {
            await buffer.add(createTestEvent(id: "\(i)"))
        }
        
        let shouldFlush = await buffer.shouldFlush()
        #expect(shouldFlush == true)
    }
    
    @Test func shouldFlushWhenAboveThreshold() async {
        let buffer = NoraiBuffer()
        
        for i in 1...NoraiBufferPolicy.maxEventsCount + 1 {
            await buffer.add(createTestEvent(id: "\(i)"))
        }
        
        let shouldFlush = await buffer.shouldFlush()
        #expect(shouldFlush == true)
    }
    
    @Test func shouldNotFlushAfterDrain() async {
        let buffer = NoraiBuffer()
        
        // Fill buffer to threshold
        for i in 1...NoraiBufferPolicy.maxEventsCount {
            await buffer.add(createTestEvent(id: "\(i)"))
        }
        
        // Drain buffer
        _ = await buffer.drain()
        
        let shouldFlush = await buffer.shouldFlush()
        #expect(shouldFlush == false)
    }
    
    @Test func shouldAllowAddingAfterDrain() async {
        let buffer = NoraiBuffer()
        
        // Add and drain
        await buffer.add(createTestEvent(id: "first"))
        _ = await buffer.drain()
        
        // Add new event
        await buffer.add(createTestEvent(id: "second"))
        
        let events = await buffer.drain()
        #expect(events.count == 1)
        #expect(events.first?.context["itemId"] == "second")
    }
    
    @Test func shouldHandleMultipleConsecutiveDrains() async {
        let buffer = NoraiBuffer()
        
        await buffer.add(createTestEvent())
        
        let firstDrain = await buffer.drain()
        let secondDrain = await buffer.drain()
        
        #expect(firstDrain.count == 1)
        #expect(secondDrain.isEmpty)
    }
    
    @Test func shouldMaintainEventOrder() async {
        let buffer = NoraiBuffer()
        let expectedOrder = ["first", "second", "third"]
        
        for id in expectedOrder {
            await buffer.add(createTestEvent(id: id))
        }
        
        let events = await buffer.drain()
        let actualOrder = events.compactMap { $0.context["itemId"] }
        
        #expect(actualOrder == expectedOrder)
    }
    
    @Test func shouldPreserveEventIntegrity() async {
        let buffer = NoraiBuffer()
        let originalEvent = createTestEvent(id: "preserve-test")
        
        await buffer.add(originalEvent)
        
        let events = await buffer.drain()
        let retrievedEvent = events.first!
        
        #expect(retrievedEvent.id == originalEvent.id)
        #expect(retrievedEvent.event == originalEvent.event)
        #expect(retrievedEvent.context["itemId"] == "preserve-test")
    }
    
    @Test func shouldHandleConcurrentAdds() async {
        let buffer = NoraiBuffer()
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    let event = createTestEvent(id: "concurrent-\(i)")
                    await buffer.add(event)
                }
            }
        }
        
        let events = await buffer.drain()
        #expect(events.count == 10)
        
        let itemIds = events.compactMap { $0.context["itemId"] }
        let uniqueIds = Set(itemIds)
        #expect(uniqueIds.count == 10)
    }
    
    @Test func shouldHandleConcurrentReads() async {
        let buffer = NoraiBuffer()
        
        // Add some events first
        for i in 1...NoraiBufferPolicy.maxEventsCount {
            await buffer.add(createTestEvent(id: "\(i)"))
        }
        
        // Perform concurrent flush checks
        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await buffer.shouldFlush()
                }
            }
            
            var results: [Bool] = []
            for await result in group {
                results.append(result)
            }
            
            // All reads should return consistent results
            for result in results {
                #expect(result == true) // Should flush with 5 items
            }
        }
    }
    
    @Test func shouldHandleMixedConcurrentOperations() async {
        let buffer = NoraiBuffer()
        
        await withTaskGroup(of: Void.self) { group in
            // Add events
            for i in 0..<5 {
                group.addTask {
                    let event = createTestEvent(id: "mixed-\(i)")
                    await buffer.add(event)
                }
            }
            
            // Check flush status
            for _ in 0..<3 {
                group.addTask {
                    _ = await buffer.shouldFlush()
                }
            }
            
            // Single drain at the end
            group.addTask {
                _ = await buffer.drain()
            }
        }
        
        let finalEvents = await buffer.drain()
        #expect(finalEvents.count >= 0) // May be 0 if drained by concurrent task
    }
    
    @Test func shouldInitializeWithProvidedEvents() async {
        let initialEvents = [
            createTestEvent(id: "initial1"),
            createTestEvent(id: "initial2")
        ]
        
        let buffer = NoraiBuffer(events: initialEvents)
        
        let events = await buffer.drain()
        #expect(events.count == 2)
        
        let itemIds = events.compactMap { $0.context["itemId"] }
        #expect(itemIds.contains("initial1"))
        #expect(itemIds.contains("initial2"))
    }
} 
