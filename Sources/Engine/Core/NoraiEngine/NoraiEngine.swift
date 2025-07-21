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

final actor NoraiEngine {
    private let config: NoraiConfiguration
    private let logger: any NoraiLoggerProtocol
    
    private let stateManager: any NoraiEngineStateManagerProtocol
    private let enrichmentPipeline: any NoraiEnrichmentPipelineProtocol
    private let processingPipeline: any NoraiProcessingPipelineProtocol
    
    private let eventsMonitor: any NoraiEventsMonitorProtocol
    private let buffer: any NoraiBufferProtocol
    private let dispatcher: any NoraiEventsDispatcherProtocol
    private let cache: any NoraiCachingLayerProtocol

    init(
        config: NoraiConfiguration,
        logger: any NoraiLoggerProtocol,
        stateManager: any NoraiEngineStateManagerProtocol,
        enrichmentPipeline: any NoraiEnrichmentPipelineProtocol,
        processingPipeline: any NoraiProcessingPipelineProtocol,
        eventsMonitor: any NoraiEventsMonitorProtocol,
        dispatcher: any NoraiEventsDispatcherProtocol,
        cache: any NoraiCachingLayerProtocol
    ) {
        self.config = config
        self.logger = logger
        self.stateManager = stateManager
        self.enrichmentPipeline = enrichmentPipeline
        self.processingPipeline = processingPipeline
        self.eventsMonitor = eventsMonitor
        self.buffer = eventsMonitor.buffer
        self.dispatcher = dispatcher
        self.cache = cache
    }
    
    private func startListeningToMonitorStream() async throws {
        let stream: AsyncStream<Void> = eventsMonitor.listenToMonitorStream()
        Task.detached(priority: .background) {
            for await _ in stream {
                let bufferedEvents: [NoraiEvent] = await self.buffer.drain()
                guard !bufferedEvents.isEmpty else { continue }
                
                let processedEvents = await self.processingPipeline.process(events: bufferedEvents)
                guard !processedEvents.isEmpty else { continue }
                await self.dispatch(processedEvents)
                await self.logger.log("Dispatched \(processedEvents.count) Events")
            }
        }
    }
    
    private func dispatch(_ events: [NoraiEvent]) async {
        await sendCachedEventsIfAny()

        do {
            try await dispatcher.dispatch(events: events)
        } catch {
            do {
                try await cache.save(events)
                let cachedCount = await cache.getEventCount()
                let cacheSize = await cache.getCacheSize()
                await logger.log("💾 Dispatch failed - cached \(events.count) events. Total: \(cachedCount) events (\(cacheSize) bytes)")
            } catch {
                await logger.log("❌ Failed to cache events after dispatch failure: \(error.localizedDescription)")
            }
        }
    }
    
    /// Send cached events if any exist
    private func sendCachedEventsIfAny() async {
        do {
            let cachedEvents = try await cache.getAll()
            guard !cachedEvents.isEmpty else { return }
            
            await logger.log("📤 Found \(cachedEvents.count) cached events - attempting to send...")
            
            try await dispatcher.dispatch(events: cachedEvents)
            try await cache.clear()
            await logger.log("✅ Successfully sent and cleared \(cachedEvents.count) cached events")
            
        } catch {
            await logger.log("⚠️ Failed to send cached events: \(error.localizedDescription)")
        }
    }
}

extension NoraiEngine: NoraiEngineProtocol {
    func track(event: NoraiEvent) async {
        let enrichedEvent: NoraiEvent = await enrichmentPipeline.enrich(event: event)
        await buffer.add(enrichedEvent)
    }
    
    func identify(user context: NoraiUserContext) async {
        await stateManager.update(user: context)
    }
    
    func start() async throws {
        guard await stateManager.startEngine() else {
            await logger.log(NoraiEngineErrors.alreadyStarted, level: .error)
            throw NoraiEngineErrors.alreadyStarted
        }
        try await eventsMonitor.startMonitoring()
        try await startListeningToMonitorStream()
    }
}
