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
    
    // MARK: - Start Engine Tests
    
    @Test func startShouldCallStartEngineOnStateManager() async throws {
        let sut: NoraiEngine = makeSUT()
        try await sut.start()
        let startEngineMessages = await mockedStateManager.startEngineMessages
        #expect(startEngineMessages == [.startEngine])
    }
    
    @Test func startShouldCallStartMonitoring() async throws {
        let sut: NoraiEngine = makeSUT()
        try await sut.start()
        let isStartMonitoringCalled = await mockedEventsMonitor.isStartMonitoringCalled
        #expect(isStartMonitoringCalled == true)
    }
    
    @Test func startShouldMakeEngineStateRunning() async throws {
        let sut: NoraiEngine = makeSUT()
        try await sut.start()
        let isRunning = await mockedStateManager.engineState.isRunning
        #expect(isRunning == true)
    }
    
    @Test func startShouldThrowIfEngineIsAlreadyRunning() async {
        await #expect(throws: NoraiEngineErrors.alreadyStarted) {
            let sut: NoraiEngine = makeSUT()
            try await sut.start()
            try await sut.start()
        }
    }
    
    @Test func startShouldLogErrorWhenAlreadyStarted() async throws {
        let sut: NoraiEngine = makeSUT()
        try await sut.start()
        
        // Reset logger state to isolate the test
        await mockedLogger.reset()
        
        do {
            try await sut.start()
        } catch {
            // Expected to throw
        }
        
        let errorLogged = await mockedLogger.isErrorLogged
        #expect(errorLogged == true)
    }
    
    // MARK: - Track Event Tests
    
    @Test func trackShouldCallEnrichmentPipeline() async {
        let sut: NoraiEngine = makeSUT()
        let event = anyEvent()
        await sut.track(event: event)
        
        let isEnrichCalled = await mockedEnrichmentPipeline.isEnrichCalled
        let lastEnrichedEvent = await mockedEnrichmentPipeline.lastEnrichedEvent
        
        #expect(isEnrichCalled == true)
        #expect(lastEnrichedEvent?.type == event.type)
    }
    
    @Test func trackShouldAddEnrichedEventToBuffer() async {
        let sut: NoraiEngine = makeSUT()
        let event = anyEvent()
        
        // Configure enrichment pipeline to return a modified event
        let expectedEnrichedEvent = NoraiEvent(type: .itemViewed, sessionId: UUID())
        await mockedEnrichmentPipeline.setEnrichedEvent(expectedEnrichedEvent)
        
        await sut.track(event: event)
        
        let isAddCalled = await mockedBuffer.isAddCalled
        let lastAddedEvent = await mockedBuffer.lastAddedEvent
        
        #expect(isAddCalled == true)
        #expect(lastAddedEvent?.sessionId == expectedEnrichedEvent.sessionId)
    }
    
    @Test func trackShouldLogEvent() async {
        let sut: NoraiEngine = makeSUT()
        await sut.track(event: anyEvent())
        
        let isLogCalled: Bool = await mockedLogger.isLogCalled
        #expect(isLogCalled == true)
    }
    
    @Test func trackShouldLogEventAddedToBuffer() async {
        let sut: NoraiEngine = makeSUT()
        let event = NoraiEvent(type: .itemViewed)
        await sut.track(event: event)
        
        let logMessages = await mockedLogger.logMessages
        let hasBufferMessage = logMessages.contains { $0.contains("Event added to buffer: item_viewed") }
        #expect(hasBufferMessage == true)
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
        let sut: NoraiEngine = makeSUT()
        
        try await sut.start()
        
        // Give a moment for async stream setup
        try await Task.sleep(for: .milliseconds(10))
        
        // Verify that the stream listener was set up
        let isListenCalled = await mockedEventsMonitor.isListentoMonitorStreamCalled
        #expect(isListenCalled == true)
    }
    
    @Test func bufferShouldDrainEventsCorrectly() async {
        // Test buffer drainage directly
        let events = [
            NoraiEvent(type: .itemViewed),
            NoraiEvent(type: .itemFocusStarted)
        ]
        await mockedBuffer.setEvents(events)
        
        let drainedEvents = await mockedBuffer.drain()
        
        #expect(drainedEvents.count == 2)
        #expect(drainedEvents[0].type == .itemViewed)
        #expect(drainedEvents[1].type == .itemFocusStarted)
    }
    
    @Test func processingPipelineShouldProcessEvents() async {
        // Test processing pipeline directly
        let events = [NoraiEvent(type: .itemViewed)]
        let processedEvents = [NoraiEvent(type: .itemFocusStarted)]
        await mockedProcessingPipeline.setProcessedEvents(processedEvents)
        
        let result = await mockedProcessingPipeline.process(events: events)
        
        let isProcessCalled = await mockedProcessingPipeline.isProcessCalled
        #expect(isProcessCalled == true)
        #expect(result.count == 1)
        #expect(result.first?.type == .itemFocusStarted)
    }
    
    // MARK: - Time-Based Stream Processing Tests
    
    @Test func streamProcessingShouldFlushBasedOnTime() async throws {
        let testClock = TestClock()
        let testBuffer = NoraiBuffer()
        let testEventsMonitor = TestEventsMonitor(
            buffer: testBuffer,
            clock: testClock,
            logger: mockedLogger
        )
        
        let sut = makeTimedSUT(eventsMonitor: testEventsMonitor)
        
        // Add events to buffer
        await testBuffer.add(anyEvent())
        
        try await sut.start()
        
        // Use Task for clock advancement to ensure proper async execution
        await Task {
            // Initially no flush should occur (first tick is immediate)
            await testClock.advance(by: .seconds(1))
            
            // After 5 seconds, should trigger flush
            await testClock.advance(by: .seconds(5))
        }.value
        
        // Verify events were processed
        let isProcessCalled = await mockedProcessingPipeline.isProcessCalled
        let isDispatchCalled = await mockedDispatcher.isDispatchCalled
        
        #expect(isProcessCalled == true)
        #expect(isDispatchCalled == true)
    }
    
    @Test func streamProcessingShouldFlushBasedOnBufferSize() async throws {
        let testClock = TestClock()
        let testBuffer = NoraiBuffer()
        let testEventsMonitor = TestEventsMonitor(
            buffer: testBuffer,
            clock: testClock,
            logger: mockedLogger
        )
        
        let sut = makeTimedSUT(eventsMonitor: testEventsMonitor)
        
        try await sut.start()
        
        // Add enough events to trigger buffer flush (3 events)
        await testBuffer.add(anyEvent())
        await testBuffer.add(anyEvent())
        await testBuffer.add(anyEvent())
        
        // Use Task for clock advancement to ensure proper async execution
        await Task {
            await testClock.advance(by: .seconds(1))
        }.value
        
        // Verify events were processed
        let isProcessCalled = await mockedProcessingPipeline.isProcessCalled
        let isDispatchCalled = await mockedDispatcher.isDispatchCalled
        
        #expect(isProcessCalled == true)
        #expect(isDispatchCalled == true)
    }
    
    // MARK: - Integration Tests
    
    @Test func fullFlowShouldWork() async throws {
        let sut: NoraiEngine = makeSUT()
        
        // Start the engine
        try await sut.start()
        
        // Track some events
        let event1 = NoraiEvent(type: .itemViewed)
        let event2 = NoraiEvent(type: .itemFocusStarted)
        
        await sut.track(event: event1)
        await sut.track(event: event2)
        
        // Verify events were enriched and added to buffer
        let isEnrichCalled = await mockedEnrichmentPipeline.isEnrichCalled
        let isAddCalled = await mockedBuffer.isAddCalled
        
        #expect(isEnrichCalled == true)
        #expect(isAddCalled == true)
        
        // Since this is an integration test, just verify basic tracking works
        // The stream processing is tested separately with TestClock
        
        // Verify events were enriched and added to buffer
        let isEnrichCalledAgain = await mockedEnrichmentPipeline.isEnrichCalled
        let isAddCalledAgain = await mockedBuffer.isAddCalled
        
        #expect(isEnrichCalledAgain == true)
        #expect(isAddCalledAgain == true)
    }
    
    @Test func concurrentTrackingEventsShouldWork() async throws {
        let sut: NoraiEngine = makeSUT()
        
        // Track multiple events concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    let event = NoraiEvent(type: .itemViewed, context: EventContext(itemId: "item-\(i)"))
                    await sut.track(event: event)
                }
            }
        }
        
        // All events should be tracked successfully
        let isEnrichCalled = await mockedEnrichmentPipeline.isEnrichCalled
        let isAddCalled = await mockedBuffer.isAddCalled
        
        #expect(isEnrichCalled == true)
        #expect(isAddCalled == true)
    }
    
    // MARK: - Error Handling Tests
    
    @Test func engineShouldHandleEnrichmentErrors() async {
        let sut: NoraiEngine = makeSUT()
        
        // Configure enrichment to fail
        await mockedEnrichmentPipeline.setShouldFail(true)
        
        // Should not throw - errors should be handled gracefully
        await sut.track(event: anyEvent())
        
        // Should still attempt to log and add to buffer with original event
        let isLogCalled = await mockedLogger.isLogCalled
        #expect(isLogCalled == true)
    }
    
    // MARK: - Configuration Tests
    
    @Test func engineShouldUseConfigurationLogLevel() async {
        let debugConfig = NoraiConfiguration(apiKey: "test", environment: .sandbox, logLevel: .debug)
        let sut = NoraiEngine(
            config: debugConfig,
            logger: mockedLogger,
            stateManager: mockedStateManager,
            enrichmentPipeline: mockedEnrichmentPipeline,
            processingPipeline: mockedProcessingPipeline,
            eventsMonitor: mockedEventsMonitor,
            dispatcher: mockedDispatcher,
            cache: mockedCache
        )
        
        await sut.track(event: anyEvent())
        
        let logLevel = await mockedLogger.lastLogLevel
        #expect(logLevel == .debug)
    }
    
    // MARK: - Helper Methods
    
    func makeSUT() -> NoraiEngine {
        NoraiEngine(config: configuration,
                    logger: mockedLogger,
                    stateManager: mockedStateManager,
                    enrichmentPipeline: mockedEnrichmentPipeline,
                    processingPipeline: mockedProcessingPipeline,
                    eventsMonitor: mockedEventsMonitor,
                    dispatcher: mockedDispatcher,
                    cache: mockedCache)
    }
    
    func makeTimedSUT(eventsMonitor: TestEventsMonitor) -> NoraiEngine {
        NoraiEngine(config: configuration,
                    logger: mockedLogger,
                    stateManager: mockedStateManager,
                    enrichmentPipeline: mockedEnrichmentPipeline,
                    processingPipeline: mockedProcessingPipeline,
                    eventsMonitor: eventsMonitor,
                    dispatcher: mockedDispatcher,
                    cache: mockedCache)
    }
    
    func anyEvent() -> NoraiEvent {
        NoraiEvent(type: EventType.allCases.randomElement()!)
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
