//
//  NoraiEngine.swift
//  Norai
//
//  Created by Amr on 28/06/2025.
//

import Foundation

public enum NoraiEngineErrors: Error {
    case alreadyStarted
    case failedToDispatchEvents
}

public final actor NoraiEngine {
    private let config: NoraiConfiguration
    private let logger: any NoraiLoggerProtocol
    
    private let stateManager: any NoraiEngineStateManagerProtocol
    private let enrichmentPipeline: any NoraiEnrichmentPipelineProtocol
    
    private let eventsMonitor: any NoraiEventsMonitorProtocol
    private let buffer: any NoraiBufferProtocol
    private let dispatcher: any NoraiEventsDispatcherProtocol

    public init(
        config: NoraiConfiguration,
        logger: any NoraiLoggerProtocol,
        stateManager: any NoraiEngineStateManagerProtocol,
        enrichmentPipeline: any NoraiEnrichmentPipelineProtocol,
        eventsMonitor: any NoraiEventsMonitorProtocol,
        dispatcher: any NoraiEventsDispatcherProtocol
    ) {
        self.config = config
        self.logger = logger
        self.stateManager = stateManager
        self.enrichmentPipeline = enrichmentPipeline
        self.eventsMonitor = eventsMonitor
        self.buffer = eventsMonitor.buffer
        self.dispatcher = dispatcher
    }
    
    private func startListeningToMonitorStream() async throws {
        let stream: AsyncStream<Void> = eventsMonitor.listenToMonitorStream()
        Task.detached(priority: .background) {
            for await _ in stream {
                let bufferedEvents: [NoraiEvent] = await self.buffer.drain()
                do {
                    try await self.dispatcher.dispatch(events: bufferedEvents)
                } catch {
                    throw NoraiEngineErrors.failedToDispatchEvents
                }
            }
        }
    }
}

extension NoraiEngine: NoraiEngineProtocol {
    public func track(event: NoraiEvent) async {
        let enrichedEvent: NoraiEvent = await enrichmentPipeline.enrich(event: event)
        await logger.log(enrichedEvent, level: config.logLevel)
        await buffer.add(enrichedEvent)
    }
    
    public func identify(user context: NoraiUserContext) async {
        await stateManager.update(user: context)
    }
    
    public func start() async throws {
        guard await stateManager.startEngine() else {
            await logger.log(NoraiEngineErrors.alreadyStarted, level: .error)
            throw NoraiEngineErrors.alreadyStarted
        }
        try await eventsMonitor.startMonitoring()
        try await startListeningToMonitorStream()
    }
}
