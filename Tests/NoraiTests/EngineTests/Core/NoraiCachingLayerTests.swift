//
//  NoraiCachingLayerTests.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import Foundation
import Testing
@testable import Norai

struct NoraiCachingLayerTests {
    
    // MARK: - Test Helpers
    
    private func createTestEvent(id: String = "test", type: EventType = .itemViewed) -> NoraiEvent {
        NoraiEvent(
            id: UUID(),
            type: type,
            timestamp: Date(),
            sessionId: UUID(),
            userId: "test-user",
            context: EventContext(screen: "TestScreen", itemId: id),
            metadata: EventMetadata(appVersion: nil, platform: "iOS", osVersion: "17.0"),
            tags: ["test"],
            dependencies: [],
            metaData: ["test": .string("value")]
        )
    }
    
    private func createCachingLayer() -> NoraiCachingLayer {
        let uniqueFileName = "test_cache_\(UUID().uuidString).jsonl"
        return NoraiCachingLayer(fileName: uniqueFileName)
    }
    
    // MARK: - Basic Functionality Tests
    
    @Test func shouldInitializeWithoutErrors() async {
        let cache = createCachingLayer()
        
        let count = await cache.getEventCount()
        let size = await cache.getCacheSize()
        
        #expect(count == 0)
        #expect(size == 0)
    }
    
    @Test func shouldSaveSingleEvent() async throws {
        let cache = createCachingLayer()
        let event = createTestEvent()
        
        try await cache.save([event])
        
        let count = await cache.getEventCount()
        let events = try await cache.getAll()
        
        #expect(count == 1)
        #expect(events.count == 1)
        #expect(events.first?.type == .itemViewed)
        #expect(events.first?.userId == "test-user")
    }
    
    @Test func shouldSaveMultipleEvents() async throws {
        let cache = createCachingLayer()
        let events = [
            createTestEvent(id: "event1", type: .screenViewed),
            createTestEvent(id: "event2", type: .itemViewed),
            createTestEvent(id: "event3", type: .interaction)
        ]
        
        try await cache.save(events)
        
        let count = await cache.getEventCount()
        let savedEvents = try await cache.getAll()
        
        #expect(count == 3)
        #expect(savedEvents.count == 3)
        
        // Verify all events were saved correctly
        let types = savedEvents.map { $0.type }
        #expect(types.contains(.screenViewed))
        #expect(types.contains(.itemViewed))
        #expect(types.contains(.interaction))
    }
    
    @Test func shouldAppendToExistingEvents() async throws {
        let cache = createCachingLayer()
        
        // Save first batch
        let firstBatch = [createTestEvent(id: "batch1")]
        try await cache.save(firstBatch)
        
        let countAfterFirst = await cache.getEventCount()
        #expect(countAfterFirst == 1)
        
        // Save second batch
        let secondBatch = [
            createTestEvent(id: "batch2a"),
            createTestEvent(id: "batch2b")
        ]
        try await cache.save(secondBatch)
        
        let finalCount = await cache.getEventCount()
        let allEvents = try await cache.getAll()
        
        #expect(finalCount == 3)
        #expect(allEvents.count == 3)
    }
    
    @Test func shouldClearAllEvents() async throws {
        let cache = createCachingLayer()
        
        // Save some events
        let events = [
            createTestEvent(id: "clear1"),
            createTestEvent(id: "clear2")
        ]
        try await cache.save(events)
        
        let countBeforeClear = await cache.getEventCount()
        #expect(countBeforeClear == 2)
        
        // Clear cache
        try await cache.clear()
        
        let countAfterClear = await cache.getEventCount()
        let eventsAfterClear = try await cache.getAll()
        
        #expect(countAfterClear == 0)
        #expect(eventsAfterClear.isEmpty)
    }
    
    @Test func shouldReturnEmptyArrayWhenNoEvents() async throws {
        let cache = createCachingLayer()
        
        let events = try await cache.getAll()
        let count = await cache.getEventCount()
        let size = await cache.getCacheSize()
        
        #expect(events.isEmpty)
        #expect(count == 0)
        #expect(size == 0)
    }
    
    @Test func shouldHandleEmptyEventsList() async throws {
        let cache = createCachingLayer()
        
        try await cache.save([])
        
        let count = await cache.getEventCount()
        let events = try await cache.getAll()
        
        #expect(count == 0)
        #expect(events.isEmpty)
    }
    
    // MARK: - Data Persistence Tests
    
    @Test func shouldPreserveEventData() async throws {
        let cache = createCachingLayer()
        
        let originalEvent = NoraiEvent(
            id: UUID(),
            type: .screenViewed,
            timestamp: Date(),
            sessionId: UUID(),
            userId: "preserve-test",
            context: EventContext(
                screen: "PreserveScreen",
                component: "PreserveComponent",
                itemId: "preserve-item",
                visibilityRatio: 0.85,
                viewDuration: 5.5,
                position: 10,
                totalItems: 100
            ),
            metadata: EventMetadata(
                appVersion: "1.0.0",
                platform: "iOS",
                osVersion: "17.0",
                networkType: "wifi"
            ),
            tags: ["preserve", "test", "important"],
            dependencies: [
                EventDependency(key: "preserve-key", value: .string("preserve-value")),
                EventDependency(key: "numeric-key", value: .int(42))
            ],
            metaData: [
                "preserve": .string("metadata"),
                "number": .int(123),
                "boolean": .bool(true)
            ]
        )
        
        try await cache.save([originalEvent])
        
        let retrievedEvents = try await cache.getAll()
        #expect(retrievedEvents.count == 1)
        
        let retrievedEvent = retrievedEvents.first!
        
        // Verify all fields are preserved
        #expect(retrievedEvent.type == .screenViewed)
        #expect(retrievedEvent.userId == "preserve-test")
        #expect(retrievedEvent.context.screen == "PreserveScreen")
        #expect(retrievedEvent.context.component == "PreserveComponent")
        #expect(retrievedEvent.context.itemId == "preserve-item")
        #expect(retrievedEvent.context.visibilityRatio == 0.85)
        #expect(retrievedEvent.context.viewDuration == 5.5)
        #expect(retrievedEvent.context.position == 10)
        #expect(retrievedEvent.context.totalItems == 100)
        #expect(retrievedEvent.metadata.platform == "iOS")
        #expect(retrievedEvent.metadata.osVersion == "17.0")
        #expect(retrievedEvent.metadata.appVersion == "1.0.0")
        #expect(retrievedEvent.metadata.networkType == "wifi")
        #expect(retrievedEvent.tags.count == 3)
        #expect(retrievedEvent.tags.contains("preserve"))
        #expect(retrievedEvent.tags.contains("test"))
        #expect(retrievedEvent.tags.contains("important"))
        #expect(retrievedEvent.dependencies.count == 2)
        #expect(retrievedEvent.metaData.count == 3)
        
        // Verify dependency values
        let preserveDep = retrievedEvent.dependencies.first { $0.key == "preserve-key" }
        if case .string(let value) = preserveDep?.value {
            #expect(value == "preserve-value")
        } else {
            Issue.record("Preserve dependency not found or wrong type")
        }
        
        // Verify metadata values
        if case .string(let preserveValue) = retrievedEvent.metaData["preserve"] {
            #expect(preserveValue == "metadata")
        } else {
            Issue.record("Preserve metadata not found or wrong type")
        }
        
        if case .int(let numberValue) = retrievedEvent.metaData["number"] {
            #expect(numberValue == 123)
        } else {
            Issue.record("Number metadata not found or wrong type")
        }
        
        if case .bool(let boolValue) = retrievedEvent.metaData["boolean"] {
            #expect(boolValue == true)
        } else {
            Issue.record("Boolean metadata not found or wrong type")
        }
    }
    
    // MARK: - Performance and Size Management Tests
    
    @Test func shouldReportCorrectCacheSize() async throws {
        let cache = createCachingLayer()
        
        let initialSize = await cache.getCacheSize()
        #expect(initialSize == 0)
        
        let event = createTestEvent()
        try await cache.save([event])
        
        let sizeAfterSave = await cache.getCacheSize()
        #expect(sizeAfterSave > 0)
        
        try await cache.clear()
        
        let sizeAfterClear = await cache.getCacheSize()
        #expect(sizeAfterClear == 0)
    }
    
    @Test func shouldHandleConcurrentOperations() async throws {
        let cache = createCachingLayer()
        
        // Perform concurrent save operations
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    let event = createTestEvent(id: "concurrent-\(i)")
                    try? await cache.save([event])
                }
            }
        }
        
        let finalCount = await cache.getEventCount()
        let allEvents = try await cache.getAll()
        
        #expect(finalCount == 5)
        #expect(allEvents.count == 5)
        
        // Verify all events have unique IDs
        let itemIds = allEvents.compactMap { $0.context.itemId }
        let uniqueIds = Set(itemIds)
        #expect(uniqueIds.count == 5)
    }
    
    // MARK: - Error Handling Tests
    
    @Test func shouldHandleCorruptedDataGracefully() async throws {
        // This test would require manually creating corrupted files
        // For now, we test that the system handles empty/missing files gracefully
        let cache = createCachingLayer()
        
        // Try to get events from non-existent cache
        let events = try await cache.getAll()
        #expect(events.isEmpty)
        
        // Try to clear non-existent cache
        try await cache.clear() // Should not throw
        
        let count = await cache.getEventCount()
        #expect(count == 0)
    }
} 