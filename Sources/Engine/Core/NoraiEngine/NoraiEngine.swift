//
//  NoraiEngine.swift
//  Norai
//
//  Created by Amr on 28/06/2025.
//

import Foundation

public enum NoraiEngineErrors: Error {
    case alreadyStarted
}

public final class NoraiEngine {
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
}

extension NoraiEngine: NoraiEngineProtocol {
    public func track(event: NoraiEvent) async {
        let enrichedEvent: NoraiEvent = await enrichmentPipeline.enrich(event: event)
        await logger.log(enrichedEvent, level: config.logLevel)
    }
    
    public func identify(user context: NoraiUserContext) async {
        await stateManager.update(user: context)
    }
    
    public func start() async throws {
        guard try await stateManager.startEngine() else {
            await logger.log(NoraiEngineErrors.alreadyStarted, level: .error)
            throw NoraiEngineErrors.alreadyStarted
        }
        try await eventsMonitor.startMonitoring(with: self)
    }
}

extension NoraiEngine: NoraiEventsMonitorDelegateProtocol {
    public func shouldFlush() async {
        let bufferedEvents: [NoraiEvent] = await buffer.drain()
        do {
            try await dispatcher.dispatch(events: bufferedEvents)
        } catch {
            // TODO: Network unavailable error
        }
    }
}
