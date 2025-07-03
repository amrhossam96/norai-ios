//
//  NoraiEngineTests.swift
//  Norai
//
//  Created by Amr on 28/06/2025.
//

import Foundation
import Norai
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
        let isStartEngineCalled = await mockedStateManager.isStartEngineCalled
        #expect(isStartEngineCalled == true)
    }
    
    @Test func startShouldCallStartMonitoring() async throws {
        let sut: NoraiEngine = makeSUT()
        try await sut.start()
        let isStartMonitoringCalled = await mockedEventsMonitor.isStartMonitoringCalled
        #expect(isStartMonitoringCalled == true)
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
}
