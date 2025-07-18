//
//  EnrichersTests.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import Foundation
@testable import Norai
import Testing

struct EnrichersTests {
    
    // MARK: - Mock Dependencies
    
    actor MockNetworkMonitor: NoraiNetworkMonitorProtocol {
        var networkAvailable = true
        
        func isNetworkAvailable() async -> Bool {
            return networkAvailable
        }
        
        func startMonitoring() async {
            // Mock implementation
        }
    }
    
    // MARK: - Test Helpers
    
    private func createTestEvent(eventName: String = "item_viewed") -> NoraiEvent {
        NoraiEvent(
            event: eventName,
            context: ["itemId": "test-item"]
        )
    }
    
    private func createTestState(
        screen: String? = "TestScreen",
        userContext: NoraiUserContext? = nil
    ) -> NoraiEngineState {
        NoraiEngineState(
            isRunning: true,
            sessionId: UUID(),
            lastScreen: screen,
            userContext: userContext
        )
    }
    
    // MARK: - Timestamp Enricher Tests
    
    @Test func timestampEnricherShouldAddTimestampWhenMissing() async {
        let enricher = TimestampEnricher()
        let state = createTestState()
        var event = createTestEvent()
        event.timestamp = nil // Ensure no timestamp
        
        let beforeEnrichment = Date()
        let enrichedEvent = await enricher.enrich(event: event, with: state)
        let afterEnrichment = Date()
        
        #expect(enrichedEvent.timestamp != nil)
        #expect(enrichedEvent.timestamp! >= beforeEnrichment)
        #expect(enrichedEvent.timestamp! <= afterEnrichment)
    }
    
    @Test func timestampEnricherShouldPreserveExistingTimestamp() async {
        let enricher = TimestampEnricher()
        let state = createTestState()
        let existingTimestamp = Date(timeIntervalSince1970: 1000)
        
        var event = createTestEvent()
        event.timestamp = existingTimestamp
        
        let enrichedEvent = await enricher.enrich(event: event, with: state)
        
        #expect(enrichedEvent.timestamp == existingTimestamp)
    }
    
    @Test func timestampEnricherShouldPreserveOtherEventProperties() async {
        let enricher = TimestampEnricher()
        let state = createTestState()
        
        var event = createTestEvent(eventName: "screen_viewed")
        event.userId = "test-user"
        event.context["screen"] = "TestScreen"
        event.tags = ["test", "enrichment"]
        
        let enrichedEvent = await enricher.enrich(event: event, with: state)
        
        #expect(enrichedEvent.event == "screen_viewed")
        #expect(enrichedEvent.userId == "test-user")
        #expect(enrichedEvent.context["screen"] == "TestScreen")
        #expect(enrichedEvent.tags == ["test", "enrichment"])
    }
    
    // MARK: - Screen Context Enricher Tests
    
    @Test func screenContextEnricherShouldAddScreenFromState() async {
        let enricher = ScreenContextEnricher()
        let state = createTestState(screen: "HomeScreen")
        let event = createTestEvent()
        
        let enrichedEvent = await enricher.enrich(event: event, with: state)
        
        #expect(enrichedEvent.context["screen"] == "HomeScreen")
        #expect(enrichedEvent.sessionId == state.sessionId)
    }
    
    @Test func screenContextEnricherShouldOverwriteScreen() async {
        let enricher = ScreenContextEnricher()
        let state = createTestState(screen: "NewScreen")
        
        var event = createTestEvent()
        event.context["screen"] = "OldScreen"
        
        let enrichedEvent = await enricher.enrich(event: event, with: state)
        
        #expect(enrichedEvent.context["screen"] == "NewScreen")
    }
    
    @Test func screenContextEnricherShouldAddSessionId() async {
        let enricher = ScreenContextEnricher()
        let state = createTestState()
        var event = createTestEvent()
        event.sessionId = nil
        
        let enrichedEvent = await enricher.enrich(event: event, with: state)
        
        #expect(enrichedEvent.sessionId == state.sessionId)
    }
    
    @Test func screenContextEnricherShouldOverwriteSessionId() async {
        let enricher = ScreenContextEnricher()
        let state = createTestState()
        
        var event = createTestEvent()
        event.sessionId = UUID() // Different session
        
        let enrichedEvent = await enricher.enrich(event: event, with: state)
        
        #expect(enrichedEvent.sessionId == state.sessionId)
    }
    
    // MARK: - User Context Enricher Tests
    
    @Test func userContextEnricherShouldAddUserMetadataFromState() async {
        let enricher = UserContextEnricher()
        let userContext = NoraiUserContext(
            id: "user-123",
            firstName: "John",
            lastName: "Doe",
            email: "john.doe@example.com",
            isLoggedIn: true
        )
        let state = createTestState(userContext: userContext)
        let event = createTestEvent()
        
        let enrichedEvent = await enricher.enrich(event: event, with: state)
        
        #expect(enrichedEvent.properties["user.id"] == "user-123")
        #expect(enrichedEvent.properties["user.firstName"] == "John")
        #expect(enrichedEvent.properties["user.lastName"] == "Doe")
        #expect(enrichedEvent.properties["user.email"] == "john.doe@example.com")
        #expect(enrichedEvent.properties["user.isLoggedIn"] == "true")
    }
    
    @Test func userContextEnricherShouldHandleNilUserContext() async {
        let enricher = UserContextEnricher()
        let state = createTestState(userContext: nil)
        let event = createTestEvent()
        
        let enrichedEvent = await enricher.enrich(event: event, with: state)
        
        #expect(enrichedEvent.properties["user.id"] == "")
        #expect(enrichedEvent.properties["user.firstName"] == "")
        #expect(enrichedEvent.properties["user.lastName"] == "")
        #expect(enrichedEvent.properties["user.email"] == "")
        #expect(enrichedEvent.properties["user.isLoggedIn"] == "false")
    }
    
    @Test func userContextEnricherShouldHandleUserContextWithNilId() async {
        let enricher = UserContextEnricher()
        let userContext = NoraiUserContext(
            id: nil,
            firstName: "Jane",
            lastName: "Smith",
            email: "jane@example.com",
            isLoggedIn: false
        )
        let state = createTestState(userContext: userContext)
        let event = createTestEvent()
        
        let enrichedEvent = await enricher.enrich(event: event, with: state)
        
        #expect(enrichedEvent.properties["user.id"] == "")
        #expect(enrichedEvent.properties["user.firstName"] == "Jane")
        #expect(enrichedEvent.properties["user.lastName"] == "Smith")
        #expect(enrichedEvent.properties["user.isLoggedIn"] == "false")
    }
    
    @Test func userContextEnricherShouldPreserveExistingUserId() async {
        let enricher = UserContextEnricher()
        let userContext = NoraiUserContext(id: "state-user", isLoggedIn: true)
        let state = createTestState(userContext: userContext)
        
        var event = createTestEvent()
        event.userId = "existing-user"
        
        let enrichedEvent = await enricher.enrich(event: event, with: state)
        
        // Should add to properties but preserve userId field
        #expect(enrichedEvent.userId == "existing-user")
        #expect(enrichedEvent.properties["user.id"] == "state-user")
    }
    
    // MARK: - Device Metadata Enricher Tests
    
    @Test func deviceMetadataEnricherShouldAddPlatformInfo() async {
        let enricher = DeviceMetadataEnricher()
        let state = createTestState()
        let event = createTestEvent()
        
        let enrichedEvent = await enricher.enrich(event: event, with: state)
        
        #expect(enrichedEvent.metadata.platform != nil)
    }
    
    @Test func deviceMetadataEnricherShouldAddOSVersion() async {
        let enricher = DeviceMetadataEnricher()
        let state = createTestState()
        let event = createTestEvent()
        
        let enrichedEvent = await enricher.enrich(event: event, with: state)
        
        #expect(enrichedEvent.metadata.osVersion != nil)
    }
    
    @Test func deviceMetadataEnricherShouldOverwriteExistingMetadata() async {
        let enricher = DeviceMetadataEnricher()
        let state = createTestState()
        
        var event = createTestEvent()
        event.metadata.platform = "Web"
        event.metadata.osVersion = "Unknown"
        
        let enrichedEvent = await enricher.enrich(event: event, with: state)
        
        // Should overwrite with actual device info
        #if canImport(UIKit)
        #expect(enrichedEvent.metadata.platform == "iOS")
        #else
        #expect(enrichedEvent.metadata.platform == "macOS")
        #endif
        #expect(enrichedEvent.metadata.osVersion != "Unknown")
    }
    
    // MARK: - Network Context Enricher Tests
    
    @Test func networkContextEnricherShouldAddNetworkMetadata() async {
        let mockNetworkMonitor = MockNetworkMonitor()
        let enricher = NetworkContextEnricher(networkMonitor: mockNetworkMonitor)
        let state = createTestState()
        let event = createTestEvent()
        
        let enrichedEvent = await enricher.enrich(event: event, with: state)
        
        #expect(enrichedEvent.metadata.networkType != nil)
    }
    
    @Test func networkContextEnricherShouldPreserveExistingDependencies() async {
        let mockNetworkMonitor = MockNetworkMonitor()
        let enricher = NetworkContextEnricher(networkMonitor: mockNetworkMonitor)
        let state = createTestState()
        
        var event = createTestEvent()
        event.properties["existingDep"] = "value"
        event.properties["anotherDep"] = "another"
        
        let enrichedEvent = await enricher.enrich(event: event, with: state)
        
        #expect(enrichedEvent.metadata.networkType != nil) // Network type added to metadata
        
        // Existing properties should be preserved
        let existingDep = enrichedEvent.properties["existingDep"]
        let anotherDep = enrichedEvent.properties["anotherDep"]
        #expect(existingDep != nil)
        #expect(anotherDep != nil)
    }
    
    // MARK: - Integration Tests
    
    @Test func enrichersShouldWorkInSequence() async {
        let timestampEnricher = TimestampEnricher()
        let screenEnricher = ScreenContextEnricher()
        let userEnricher = UserContextEnricher()
        let mockNetworkMonitor = MockNetworkMonitor()
        let networkEnricher = NetworkContextEnricher(networkMonitor: mockNetworkMonitor)
        
        let userContext = NoraiUserContext(
            id: "integration-user",
            firstName: "Integration",
            lastName: "Test",
            email: "test@integration.com",
            isLoggedIn: true
        )
        let state = createTestState(screen: "IntegrationScreen", userContext: userContext)
        
        var event = createTestEvent(eventName: "integration_event")
        event.timestamp = nil
        
        // Apply enrichers in sequence
        event = await timestampEnricher.enrich(event: event, with: state)
        event = await screenEnricher.enrich(event: event, with: state)
        event = await userEnricher.enrich(event: event, with: state)
        event = await networkEnricher.enrich(event: event, with: state)
        
        // Verify all enrichments were applied
        #expect(event.timestamp != nil)
        #expect(event.context["screen"] == "IntegrationScreen")
        #expect(event.properties["user.firstName"] == "Integration")
        #expect(event.metadata.networkType != nil) // Network type in metadata
    }
    
    @Test func enrichersShouldHandleEmptyEvents() async {
        let enricher = UserContextEnricher()
        let state = createTestState()
        let event = NoraiEvent(event: "empty_event")
        
        let enrichedEvent = await enricher.enrich(event: event, with: state)
        
        // Should not crash and should add user properties
        #expect(enrichedEvent.event == "empty_event")
        #expect(enrichedEvent.properties["user.id"] == "")
    }
    
    @Test func enrichersShouldHandleComplexEvents() async {
        let enricher = TimestampEnricher()
        let state = createTestState()
        
        var complexEvent = NoraiEvent(
            event: "complex_event",
            sessionId: UUID(),
            userId: "complex-user",
            context: [
                "screen": "ComplexScreen",
                "component": "ComplexComponent",
                "itemId": "complex-item"
            ],
            metadata: EventMetadata(platform: "iOS", osVersion: "16.0"),
            tags: ["complex", "test", "enrichment"]
        )
        complexEvent.timestamp = nil
        
        let enrichedEvent = await enricher.enrich(event: complexEvent, with: state)
        
        #expect(enrichedEvent.timestamp != nil)
        #expect(enrichedEvent.event == "complex_event")
        #expect(enrichedEvent.userId == "complex-user")
        #expect(enrichedEvent.context["screen"] == "ComplexScreen")
        #expect(enrichedEvent.metadata.platform == "iOS")
        #expect(enrichedEvent.tags.contains("complex"))
    }
    
    @Test func enrichersShouldHandleMultipleEnrichments() async {
        let enricher = DeviceMetadataEnricher()
        let state = createTestState()
        
        // Test sequential enrichment of multiple events
        var enrichedEvents: [NoraiEvent] = []
        
        for i in 1...5 {
            let event = createTestEvent(eventName: "sequential_event_\(i)")
            let enrichedEvent = await enricher.enrich(event: event, with: state)
            enrichedEvents.append(enrichedEvent)
        }
        
        #expect(enrichedEvents.count == 5)
        
        // All events should be enriched with metadata
        for event in enrichedEvents {
            #expect(event.metadata.platform != nil)
        }
    }
} 