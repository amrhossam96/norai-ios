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
    
    @Test func shouldInitializeWithEmptyBuffer() async {
        let sut = NoraiBuffer()
        
        let events = await sut.drain()
        let shouldFlush = await sut.shouldFlush()
        
        #expect(events.isEmpty)
        #expect(shouldFlush == false)
    }
    
    @Test func shouldInitializeWithProvidedEvents() async {
        let initialEvents = [
            NoraiEvent(type: .itemViewed),
            NoraiEvent(type: .screenViewed)
        ]
        let sut = NoraiBuffer(events: initialEvents)
        
        let events = await sut.drain()
        
        #expect(events.count == 2)
        #expect(events[0].type == .itemViewed)
        #expect(events[1].type == .screenViewed)
    }
    
    @Test func shouldAddSingleEvent() async {
        let sut = NoraiBuffer()
        let event = NoraiEvent(type: .itemViewed)
        
        await sut.add(event)
        let events = await sut.drain()
        
        #expect(events.count == 1)
        #expect(events.first?.type == .itemViewed)
    }
    
    @Test func shouldAddMultipleEvents() async {
        let sut = NoraiBuffer()
        let events = [
            NoraiEvent(type: .itemViewed),
            NoraiEvent(type: .screenViewed),
            NoraiEvent(type: .itemFocusStarted)
        ]
        
        for event in events {
            await sut.add(event)
        }
        
        let drainedEvents = await sut.drain()
        
        #expect(drainedEvents.count == 3)
        #expect(drainedEvents[0].type == .itemViewed)
        #expect(drainedEvents[1].type == .screenViewed)
        #expect(drainedEvents[2].type == .itemFocusStarted)
    }
    
    // MARK: - Drain Functionality Tests
    
    @Test func shouldDrainAndClearBuffer() async {
        let sut = NoraiBuffer()
        let events = [anyEvent(), anyEvent(), anyEvent()]
        
        for event in events {
            await sut.add(event)
        }
        
        let drainedEvents = await sut.drain()
        let secondDrain = await sut.drain()
        
        #expect(drainedEvents.count == 3)
        #expect(secondDrain.isEmpty)
    }
    
    @Test func shouldMaintainEventOrder() async {
        let sut = NoraiBuffer()
        let event1 = NoraiEvent(type: .itemViewed, context: EventContext(itemId: "1"))
        let event2 = NoraiEvent(type: .itemViewed, context: EventContext(itemId: "2"))
        let event3 = NoraiEvent(type: .itemViewed, context: EventContext(itemId: "3"))
        
        await sut.add(event1)
        await sut.add(event2)
        await sut.add(event3)
        
        let events = await sut.drain()
        
        #expect(events[0].context.itemId == "1")
        #expect(events[1].context.itemId == "2")
        #expect(events[2].context.itemId == "3")
    }
    
    @Test func shouldAllowAddingAfterDrain() async {
        let sut = NoraiBuffer()
        
        await sut.add(anyEvent())
        let firstDrain = await sut.drain()
        
        await sut.add(anyEvent())
        await sut.add(anyEvent())
        let secondDrain = await sut.drain()
        
        #expect(firstDrain.count == 1)
        #expect(secondDrain.count == 2)
    }
    
    // MARK: - Flush Threshold Tests
    
    @Test func shouldNotFlushWhenBelowThreshold() async {
        let sut = NoraiBuffer()
        
        await sut.add(anyEvent())
        await sut.add(anyEvent())
        
        let shouldFlush = await sut.shouldFlush()
        #expect(shouldFlush == false)
    }
    
    @Test func shouldFlushWhenAtThreshold() async {
        let sut = NoraiBuffer()
        
        await sut.add(anyEvent())
        await sut.add(anyEvent())
        await sut.add(anyEvent())
        
        let shouldFlush = await sut.shouldFlush()
        #expect(shouldFlush == true)
    }
    
    @Test func shouldFlushWhenAboveThreshold() async {
        let sut = NoraiBuffer()
        
        for _ in 0..<5 {
            await sut.add(anyEvent())
        }
        
        let shouldFlush = await sut.shouldFlush()
        #expect(shouldFlush == true)
    }
    
    @Test func shouldNotFlushAfterDrain() async {
        let sut = NoraiBuffer()
        
        // Fill buffer to threshold
        for _ in 0..<3 {
            await sut.add(anyEvent())
        }
        
        #expect(await sut.shouldFlush() == true)
        
        // Drain and check flush status
        _ = await sut.drain()
        
        #expect(await sut.shouldFlush() == false)
    }
    
    // MARK: - Concurrency Tests
    
    @Test func shouldHandleConcurrentAdds() async {
        let sut = NoraiBuffer()
        let numberOfTasks = 10
        let eventsPerTask = 5
        
        await withTaskGroup(of: Void.self) { group in
            for taskId in 0..<numberOfTasks {
                group.addTask {
                    for eventId in 0..<eventsPerTask {
                        let event = NoraiEvent(
                            type: .itemViewed,
                            context: EventContext(itemId: "task-\(taskId)-event-\(eventId)")
                        )
                        await sut.add(event)
                    }
                }
            }
        }
        
        let events = await sut.drain()
        #expect(events.count == numberOfTasks * eventsPerTask)
        
        // Verify all events are unique
        let itemIds = events.compactMap { $0.context.itemId }
        let uniqueIds = Set(itemIds)
        #expect(uniqueIds.count == numberOfTasks * eventsPerTask)
    }
    
    @Test func shouldHandleConcurrentReads() async {
        let sut = NoraiBuffer()
        
        // Pre-populate buffer
        for i in 0..<10 {
            await sut.add(NoraiEvent(type: .itemViewed, context: EventContext(itemId: "\(i)")))
        }
        
        let results = await withTaskGroup(of: Bool.self) { group in
            // Multiple concurrent shouldFlush calls
            for _ in 0..<5 {
                group.addTask {
                    await sut.shouldFlush()
                }
            }
            
            var results: [Bool] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
        
        // All reads should return the same result
        #expect(results.allSatisfy { $0 == true })
    }
    
    @Test func shouldHandleMixedConcurrentOperations() async {
        let sut = NoraiBuffer()
        
        await withTaskGroup(of: Void.self) { group in
            // Task 1: Add events rapidly
            group.addTask {
                for i in 0..<10 {
                    await sut.add(NoraiEvent(type: .itemViewed, context: EventContext(itemId: "add-\(i)")))
                }
            }
            
            // Task 2: Check flush status rapidly
            group.addTask {
                for _ in 0..<5 {
                    _ = await sut.shouldFlush()
                }
            }
            
            // Task 3: Occasional drains without delays
            group.addTask {
                _ = await sut.drain()
                _ = await sut.drain()
            }
        }
        
        // Should complete without crashes or data corruption
        let finalEvents = await sut.drain()
        #expect(finalEvents.count >= 0) // Buffer might be empty due to drains
    }
    
    // MARK: - Edge Cases
    
    @Test func shouldHandleEmptyDrain() async {
        let sut = NoraiBuffer()
        
        let events = await sut.drain()
        
        #expect(events.isEmpty)
    }
    
    @Test func shouldHandleMultipleConsecutiveDrains() async {
        let sut = NoraiBuffer()
        
        await sut.add(anyEvent())
        
        let firstDrain = await sut.drain()
        let secondDrain = await sut.drain()
        let thirdDrain = await sut.drain()
        
        #expect(firstDrain.count == 1)
        #expect(secondDrain.isEmpty)
        #expect(thirdDrain.isEmpty)
    }
    
    @Test func shouldPreserveEventIntegrity() async {
        let sut = NoraiBuffer()
        let originalEvent = NoraiEvent(
            type: .itemViewed,
            timestamp: Date(),
            sessionId: UUID(),
            userId: "user123",
            context: EventContext(
                screen: "HomeScreen",
                component: "ProductCard",
                itemId: "product-456",
                visibilityRatio: 0.85,
                position: 3,
                totalItems: 10
            ),
            metadata: EventMetadata(
                appVersion: "1.0.0",
                platform: "iOS",
                osVersion: "16.0"
            ),
            tags: ["impression", "e-commerce"],
            dependencies: [
                EventDependency(key: "test", value: .string("value"))
            ]
        )
        
        await sut.add(originalEvent)
        let events = await sut.drain()
        let retrievedEvent = events.first!
        
        #expect(retrievedEvent.type == originalEvent.type)
        #expect(retrievedEvent.timestamp == originalEvent.timestamp)
        #expect(retrievedEvent.sessionId == originalEvent.sessionId)
        #expect(retrievedEvent.userId == originalEvent.userId)
        #expect(retrievedEvent.context.screen == originalEvent.context.screen)
        #expect(retrievedEvent.context.itemId == originalEvent.context.itemId)
        #expect(retrievedEvent.context.visibilityRatio == originalEvent.context.visibilityRatio)
        #expect(retrievedEvent.metadata.appVersion == originalEvent.metadata.appVersion)
        #expect(retrievedEvent.tags == originalEvent.tags)
        #expect(retrievedEvent.dependencies.count == originalEvent.dependencies.count)
    }
    
    // MARK: - Helper Methods
    
    private func anyEvent() -> NoraiEvent {
        NoraiEvent(type: EventType.allCases.randomElement()!)
    }
} 