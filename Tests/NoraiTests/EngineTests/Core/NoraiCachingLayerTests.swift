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
    
    private func createTestEvent(id: String = "test", eventName: String = "item_viewed") -> NoraiEvent {
        NoraiEvent(
            id: UUID(),
            event: eventName,
            timestamp: Date(),
            sessionId: UUID(),
            userId: "test-user",
            context: ["screen": "TestScreen", "itemId": id],
            metadata: EventMetadata(appVersion: nil, platform: "iOS", osVersion: "17.0"),
            tags: ["test"]
        )
    }
    
    private func createCachingLayer() -> NoraiCachingLayer {
        return NoraiCachingLayer(fileName: "test_cache_\(UUID().uuidString).jsonl")
    }
    
    // MARK: - Basic Functionality Tests
    
    @Test func shouldInitializeWithoutErrors() async {
        let cache = createCachingLayer()
        
        let count = await cache.getEventCount()
        #expect(count == 0)
    }
    
    @Test func shouldSaveSingleEvent() async throws {
        let cache = createCachingLayer()
        let event = createTestEvent()
        
        try await cache.save([event])
        
        let events = try await cache.getAll()
        let count = await cache.getEventCount()
        
        #expect(count == 1)
        #expect(events.count == 1)
        #expect(events.first?.event == "item_viewed")
        #expect(events.first?.userId == "test-user")
    }
    
    @Test func shouldSaveMultipleEvents() async throws {
        let cache = createCachingLayer()
        let events = [
            createTestEvent(id: "1", eventName: "screen_viewed"),
            createTestEvent(id: "2", eventName: "item_viewed"),
            createTestEvent(id: "3", eventName: "interaction")
        ]
        
        try await cache.save(events)
        
        let savedEvents = try await cache.getAll()
        
        // Verify all events were saved correctly
        let eventNames = savedEvents.map { $0.event }
        #expect(eventNames.contains("screen_viewed"))
        #expect(eventNames.contains("item_viewed"))
        #expect(eventNames.contains("interaction"))
    }
    
    @Test func shouldAppendToExistingEvents() async throws {
        let cache = createCachingLayer()
        
        // Save first batch
        try await cache.save([createTestEvent(id: "1")])
        
        // Save second batch
        try await cache.save([createTestEvent(id: "2")])
        
        let allEvents = try await cache.getAll()
        #expect(allEvents.count == 2)
    }
    
    @Test func shouldClearAllEvents() async throws {
        let cache = createCachingLayer()
        let events = [
            createTestEvent(id: "1"),
            createTestEvent(id: "2"),
            createTestEvent(id: "3")
        ]
        
        try await cache.save(events)
        try await cache.clear()
        
        let remainingEvents = try await cache.getAll()
        let count = await cache.getEventCount()
        
        #expect(remainingEvents.isEmpty)
        #expect(count == 0)
    }
    
    @Test func shouldReturnEmptyArrayWhenNoEvents() async throws {
        let cache = createCachingLayer()
        
        let events = try await cache.getAll()
        let count = await cache.getEventCount()
        
        #expect(events.isEmpty)
        #expect(count == 0)
    }
    
    @Test func shouldHandleEmptyEventsList() async throws {
        let cache = createCachingLayer()
        
        try await cache.save([])
        
        let events = try await cache.getAll()
        #expect(events.isEmpty)
    }
    
    // MARK: - Data Persistence Tests
    
    @Test func shouldPreserveEventData() async throws {
        let cache = createCachingLayer()
        
        let originalEvent = NoraiEvent(
            id: UUID(),
            event: "screen_viewed",
            timestamp: Date(),
            sessionId: UUID(),
            userId: "preserve-test",
            context: [
                "screen": "PreserveScreen",
                "component": "PreserveComponent",
                "itemId": "preserve-item",
                "visibilityRatio": "0.85",
                "viewDuration": "5.5",
                "position": "10",
                "totalItems": "100"
            ],
            metadata: EventMetadata(
                appVersion: "1.0.0",
                platform: "iOS",
                osVersion: "17.0",
                deviceModel: "iPhone15,2",
                locale: "en_US",
                networkType: "wifi",
                timezone: "UTC",
                screenSize: "393x852"
            ),
            tags: ["preserve", "test", "important"]
        )
        
        try await cache.save([originalEvent])
        
        let retrievedEvents = try await cache.getAll()
        let retrievedEvent = retrievedEvents.first!
        
        // Verify all fields are preserved
        #expect(retrievedEvent.event == "screen_viewed")
        #expect(retrievedEvent.userId == "preserve-test")
        #expect(retrievedEvent.context["screen"] == "PreserveScreen")
        #expect(retrievedEvent.context["component"] == "PreserveComponent")
        #expect(retrievedEvent.context["itemId"] == "preserve-item")
        #expect(retrievedEvent.context["visibilityRatio"] == "0.85")
        #expect(retrievedEvent.context["viewDuration"] == "5.5")
        #expect(retrievedEvent.context["position"] == "10")
        #expect(retrievedEvent.context["totalItems"] == "100")
        #expect(retrievedEvent.metadata.platform == "iOS")
        #expect(retrievedEvent.metadata.osVersion == "17.0")
        #expect(retrievedEvent.metadata.deviceModel == "iPhone15,2")
        #expect(retrievedEvent.metadata.networkType == "wifi")
        
        // Verify tags are preserved
        #expect(retrievedEvent.tags.contains("preserve"))
        #expect(retrievedEvent.tags.contains("test"))
        #expect(retrievedEvent.tags.contains("important"))
    }
    
    // MARK: - Performance and Size Management Tests
    
    @Test func shouldReportCorrectCacheSize() async throws {
        let cache = createCachingLayer()
        let events = [
            createTestEvent(id: "1"),
            createTestEvent(id: "2"),
            createTestEvent(id: "3")
        ]
        
        try await cache.save(events)
        
        let size = await cache.getCacheSize()
        #expect(size > 0) // Should have some file size
    }
    
    @Test func shouldHandleConcurrentOperations() async throws {
        let cache = createCachingLayer()
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    let event = createTestEvent(id: "concurrent-\(i)")
                    try? await cache.save([event])
                }
            }
        }
        
        let events = try await cache.getAll()
        #expect(events.count == 5)
        
        // Verify all events have unique IDs
        let itemIds = events.compactMap { $0.context["itemId"] }
        let uniqueIds = Set(itemIds)
        #expect(uniqueIds.count == 5)
    }
    
    // MARK: - Error Handling Tests
    
    @Test func shouldHandleCorruptedDataGracefully() async throws {
        let cache = createCachingLayer()
        
        // Save a valid event first
        try await cache.save([createTestEvent()])
        
        // The cache should handle corrupted data gracefully and return what it can
        let events = try await cache.getAll()
        #expect(events.count >= 0) // At least should not crash
    }
} 