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
    private let mockedEventsMonitor: MockedEventsMonitor
    private let mockedBuffer: MockedBuffer
    private let mockedDispatcher: MockedDispatcher

    init() {
        self.configuration = NoraiConfiguration(apiKey: "", environment: .sandbox)
        self.mockedLogger = MockedNoraiLogger()
        self.mockedStateManager = MockedNoraiEngineStateManager()
        self.mockedEnrichmentPipeline = MockedEnrichmentPipeline()
        self.mockedBuffer = MockedBuffer()
        self.mockedEventsMonitor = MockedEventsMonitor(buffer: self.mockedBuffer)
        self.mockedDispatcher = MockedDispatcher()
    }
    
    @Test func startShouldCallStartEngineOnStateManager() async throws {
        let sut: NoraiEngine = makeSUT()
        try await sut.start()
        let startEngineMessages = await mockedStateManager.startEngineMessages
        #expect(startEngineMessages == [.startEngine])
    }
    
    @Test func trackShouldCallLogOnLogger() async {
        let sut: NoraiEngine = makeSUT()
        await sut.track(event: anyEvent())
        let isLogCalled: Bool = await mockedLogger.isLogCalled
        #expect(isLogCalled == true)
    }
    
    @Test func trackCallsEnrichInEnrichmentPipeline() async {
        let sut: NoraiEngine = makeSUT()
        await sut.track(event: anyEvent())
        let isEnrichCalled = await mockedEnrichmentPipeline.isEnrichCalled
        #expect(isEnrichCalled == true)
    }
    
    @Test func trackCallsLogInLogger() async {
        let sut: NoraiEngine = makeSUT()
        await sut.track(event: anyEvent())
        let isLogCalled = await mockedLogger.isLogCalled
        #expect(isLogCalled == true)
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
    
    @Test func trackShouldCallAddOnBuffer() async {
        let sut: NoraiEngine = makeSUT()
        await sut.track(event: anyEvent())
        let isAddCalled = await mockedBuffer.isAddCalled
        #expect(isAddCalled == true)
    }
    
    @Test func identifyShouldCallUpdateUserContext() async {
        let sut: NoraiEngine = makeSUT()
        await sut.identify(user: NoraiUserContext(isLoggedIn: true))
        let isUpdateCalled: Bool = await mockedStateManager.isUpdateCalled
        #expect(isUpdateCalled == true)
    }
}

extension NoraiEngineTests {
    func makeSUT() -> NoraiEngine {
        NoraiEngine(config: configuration,
                    logger: mockedLogger,
                    stateManager: mockedStateManager,
                    enrichmentPipeline: mockedEnrichmentPipeline,
                    eventsMonitor: mockedEventsMonitor,
                    dispatcher: mockedDispatcher)
    }
    
    func anyEvent() -> NoraiEvent {
        NoraiEvent(type: EventType.allCases.randomElement()!)
    }
}
