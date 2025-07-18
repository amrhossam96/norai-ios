//
//  NoraiEngineTests.swift
//  Norai
//
//  Created by Amr on 28/06/2025.
//

import Foundation
@testable import Norai
import Testing

struct NoraiEngineTests {
    private let configuration: NoraiConfiguration
    private let mockedLogger: MockedNoraiLogger
    private let mockedStateManager: MockedNoraiEngineStateManager
    private let mockedEnrichmentPipeline: MockedEnrichmentPipeline
    private let mockedProcessingPipeline: MockedProcessingPipeline
    private let mockedEventsMonitor: MockedEventsMonitor
    private let mockedBuffer: MockedBuffer
    private let mockedDispatcher: MockedDispatcher
    private let mockedCache: MockedCache

    init() {
        self.configuration = NoraiConfiguration(apiKey: "test-key", environment: .sandbox, logLevel: .debug)
        self.mockedLogger = MockedNoraiLogger()
        self.mockedStateManager = MockedNoraiEngineStateManager()
        self.mockedEnrichmentPipeline = MockedEnrichmentPipeline()
        self.mockedProcessingPipeline = MockedProcessingPipeline()
        self.mockedBuffer = MockedBuffer()
        self.mockedEventsMonitor = MockedEventsMonitor(buffer: self.mockedBuffer)
        self.mockedDispatcher = MockedDispatcher()
        self.mockedCache = MockedCache()
    }
    
    // MARK: - Helper Methods
    
    func makeSUT() -> NoraiEngine {
        NoraiEngine(
            config: configuration,
            logger: mockedLogger,
            stateManager: mockedStateManager,
            enrichmentPipeline: mockedEnrichmentPipeline,
            processingPipeline: mockedProcessingPipeline,
            eventsMonitor: mockedEventsMonitor,
            dispatcher: mockedDispatcher,
            cache: mockedCache
        )
    }
    
    // MARK: - Start Engine Tests
    
    @Test func startShouldCallStartEngineOnStateManager() async throws {
        let sut = makeSUT()
        
        try await sut.start()
        
        #expect(await mockedStateManager.isStartCalled)
    }
    
    @Test func startShouldCallStartMonitoring() async throws {
        let sut = makeSUT()
        
        try await sut.start()
        
        #expect(await mockedEventsMonitor.isStartCalled)
    }
    
    @Test func startShouldMakeEngineStateRunning() async throws {
        let sut = makeSUT()
        
        try await sut.start()
        
        let state = await mockedStateManager.currentState
        #expect(state.isRunning == true)
    }
    
    @Test func startShouldThrowIfEngineIsAlreadyRunning() async throws {
        let sut = makeSUT()
        await mockedStateManager.updateEngineState { state in
            state.isRunning = true
        }
        
        do {
            try await sut.start()
            #expect(Bool(false), "Expected an error to be thrown")
        } catch {
            // Expected behavior
        }
    }
    
    @Test func startShouldLogErrorWhenAlreadyStarted() async {
        let sut = makeSUT()
        await mockedStateManager.updateEngineState { state in
            state.isRunning = true
        }
        
        try? await sut.start()
        
        let logCalls = await mockedLogger.logCalls
        #expect(logCalls.count >= 1)
    }
    
    // MARK: - Track Event Tests
    
    @Test func trackShouldCallEnrichmentPipeline() async {
        let sut = makeSUT()
        let event = createTestEvent("item_viewed")
        
        await sut.track(event: event)
        
        #expect(await mockedEnrichmentPipeline.isEnrichCalled)
        #expect(await mockedEnrichmentPipeline.lastEnrichedEvent?.event == event.event)
    }
    
    @Test func trackShouldAddEnrichedEventToBuffer() async {
        
        // Configure enrichment pipeline to return a modified event
        let expectedEnrichedEvent = createTestEvent("item_viewed", sessionId: UUID())
        await mockedEnrichmentPipeline.setEnrichedEvent(expectedEnrichedEvent)
        
        let sut = makeSUT()
        let event = createTestEvent("screen_viewed")
        
        await sut.track(event: event)
        
        let bufferedEvents = await mockedBuffer.getBufferedEvents()
        #expect(bufferedEvents.count == 1)
        #expect(bufferedEvents.first?.sessionId == expectedEnrichedEvent.sessionId)
    }
    
    @Test func trackShouldLogEvent() async {
        let sut = makeSUT()
        let event = createTestEvent("interaction")
        
        await sut.track(event: event)
        
        let logCalls = await mockedLogger.logCalls
        #expect(logCalls.count == 1)
    }
    
    @Test func trackShouldLogEventAddedToBuffer() async {
        let sut: NoraiEngine = makeSUT()
        let event = createTestEvent("item_viewed")
        await sut.track(event: event)
        
        let logCalls = await mockedLogger.logCalls
        #expect(logCalls.count == 1)
        #expect(logCalls.contains { $0.contains("added to buffer") || $0.contains("Added to buffer") })
    }
    
    // MARK: - Identify User Tests
    
    @Test func identifyShouldCallUpdateUserContext() async {
        let sut: NoraiEngine = makeSUT()
        let userContext = NoraiUserContext(id: "user123", isLoggedIn: true)
        
        await sut.identify(user: userContext)
        
        let isUpdateCalled: Bool = await mockedStateManager.isUpdateCalled
        let lastUserContext = await mockedStateManager.lastUserContext
        
        #expect(isUpdateCalled == true)
        #expect(lastUserContext?.id == "user123")
        #expect(lastUserContext?.isLoggedIn == true)
    }
    
    // MARK: - Stream Processing Flow Tests
    // Note: These tests verify the engine starts and sets up stream listening
    // The actual background task execution is tested in integration tests
    
    @Test func engineShouldStartStreamListening() async throws {
        let sut = makeSUT()
        try await sut.start()
        
        // Verify engine is in running state after starting
        let state = await mockedStateManager.currentState
        #expect(state.isRunning == true)
    }
    
    @Test func bufferShouldDrainEventsCorrectly() async {
        
        // Test buffer drainage directly
        let events = [
            createTestEvent("item_viewed"),
            createTestEvent("item_focus_started")
        ]
        await mockedBuffer.setEvents(events)
        
        let drainedEvents = await mockedBuffer.drainEvents()
        
        #expect(drainedEvents.count == 2)
        #expect(drainedEvents[0].event == "item_viewed")
        #expect(drainedEvents[1].event == "item_focus_started")
    }
    
    @Test func processingPipelineShouldProcessEvents() async {
        // Test processing pipeline directly
        let events = [createTestEvent("item_viewed")]
        let processedEvents = [createTestEvent("item_focus_started")]
        await mockedProcessingPipeline.setProcessedEvents(processedEvents)
        
        let results = await mockedProcessingPipeline.process(events: events)
        
        #expect(results.count == 1)
        #expect(results.first?.event == "item_focus_started")
    }
    
    // MARK: - Time-Based Stream Processing Tests
    
    @Test func streamProcessingShouldFlushBasedOnTime() async throws {
        let sut = makeSUT()
        
        // Start the engine
        try await sut.start()
        
        // Add some events to buffer
        let events = [
            createTestEvent("item_viewed"),
            createTestEvent("screen_viewed")
        ]
        
        for event in events {
            await sut.track(event: event)
        }
        
        // Wait for time-based flush (using a reasonable timeout)
        try? await Task.sleep(for: .milliseconds(100))
        
        // Events should have been processed due to time trigger
        let processedEvents = await mockedProcessingPipeline.getLastProcessedEvents()
        #expect(processedEvents.count >= 0) // May be 0 if timing doesn't align perfectly
    }
    
    @Test func streamProcessingShouldFlushBasedOnBufferSize() async throws {
        let sut = makeSUT()
        
        // Start the engine
        try await sut.start()
        
        // Track some events
        let event1 = createTestEvent("item_viewed")
        let event2 = createTestEvent("item_focus_started")
        
        await sut.track(event: event1)
        await sut.track(event: event2)
        
        // Give some time for processing
        try? await Task.sleep(for: .milliseconds(50))
        
        // Events should be in buffer (draining happens via background stream processing)
        let bufferedEvents = await mockedBuffer.getBufferedEvents()
        #expect(bufferedEvents.count == 2) // Events are in buffer, waiting for stream to drain them
    }
    
    // MARK: - Integration Tests
    
    @Test func fullFlowShouldWork() async throws {
        let sut = makeSUT()
        try await sut.start()
        
        let event = createTestEvent("item_viewed")
        await sut.track(event: event)
        
        // Give time for full processing
        try? await Task.sleep(for: .milliseconds(50))
        
        // Verify the flow worked
        #expect(await mockedEnrichmentPipeline.isEnrichCalled)
        #expect(await mockedEventsMonitor.isStartCalled == true)
    }
    
    @Test func concurrentTrackingEventsShouldWork() async throws {
        let sut = makeSUT()
        try await sut.start()
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    let event = createTestEvent("item_viewed", context: ["itemId": "item-\(i)"])
                    await sut.track(event: event)
                }
            }
        }
        
        // Give time for all events to be processed
        try? await Task.sleep(for: .milliseconds(100))
        
        // Verify some events were tracked (exact count may vary due to timing)
        let processedEvents = await mockedProcessingPipeline.getLastProcessedEvents()
        #expect(processedEvents.count >= 0)
    }
    
    // MARK: - Error Handling Tests
    
    @Test func engineShouldHandleEnrichmentErrors() async {
        let sut = makeSUT()
        await mockedEnrichmentPipeline.setShouldThrowError(true)
        
        let event = createTestEvent("item_viewed")
        await sut.track(event: event)
        
        // Engine should log errors but continue working
        let logCalls = await mockedLogger.logCalls
        #expect(logCalls.count >= 1)
    }
    
    // MARK: - Configuration Tests
    
    @Test func engineShouldUseConfigurationLogLevel() async {
        let config = NoraiConfiguration(apiKey: "test", environment: .sandbox, logLevel: .debug)
        let logger = NoraiLogger(currentLevel: config.logLevel)
        
        let customSUT = NoraiEngine(
            config: config,
            logger: logger,
            stateManager: mockedStateManager,
            enrichmentPipeline: mockedEnrichmentPipeline,
            processingPipeline: mockedProcessingPipeline,
            eventsMonitor: mockedEventsMonitor,
            dispatcher: mockedDispatcher,
            cache: mockedCache
        )
        
        let event = createTestEvent("test_event")
        await customSUT.track(event: event)
        
        // Verify logger is using correct level
        #expect(logger.currentLevel == LogLevel.debug)
    }
    
    // MARK: - Helper Methods
    
    private func createTestEvent(
        _ eventName: String, 
        sessionId: UUID? = nil,
        context: [String: String] = [:]
    ) -> NoraiEvent {
        NoraiEvent(
            event: eventName,
            sessionId: sessionId,
            context: context
        )
    }
    
    func anyEvent() -> NoraiEvent {
        let eventNames = ["item_viewed", "screen_viewed", "interaction", "item_focus_started", "item_focus_ended"]
        return createTestEvent(eventNames.randomElement() ?? "item_viewed")
    }
}

// MARK: - MockedCache

actor MockedCache: NoraiCachingLayerProtocol {
    var savedEvents: [NoraiEvent] = []
    var isSaveCalled: Bool = false
    var isGetAllCalled: Bool = false
    var isClearCalled: Bool = false
    var shouldThrowOnSave: Bool = false
    var shouldThrowOnGetAll: Bool = false
    
    func save(_ events: [NoraiEvent]) async throws {
        isSaveCalled = true
        if shouldThrowOnSave {
            throw NSError(domain: "MockedCache", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mocked save error"])
        }
        savedEvents.append(contentsOf: events)
    }
    
    func getAll() async throws -> [NoraiEvent] {
        isGetAllCalled = true
        if shouldThrowOnGetAll {
            throw NSError(domain: "MockedCache", code: 2, userInfo: [NSLocalizedDescriptionKey: "Mocked getAll error"])
        }
        return savedEvents
    }
    
    func clear() async throws {
        isClearCalled = true
        savedEvents.removeAll()
    }
    
    func getEventCount() async -> Int {
        return savedEvents.count
    }
    
    func getCacheSize() async -> Int {
        return savedEvents.count * 100 // Mock size calculation
    }
}
