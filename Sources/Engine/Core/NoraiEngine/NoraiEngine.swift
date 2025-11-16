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
    
    // MARK: - Dependencies
    
    private let config: NoraiConfiguration
    private let logger: any NoraiLoggerProtocol
    private let stateManager: any NoraiEngineStateManagerProtocol
    private let enrichmentPipeline: any NoraiEnrichmentPipelineProtocol
    private let processingPipeline: any NoraiProcessingPipelineProtocol
    private let eventsMonitor: any NoraiEventsMonitorProtocol
    private let buffer: any NoraiBufferProtocol
    private let dispatcher: any NoraiEventsDispatcherProtocol
    private let cache: any NoraiCachingLayerProtocol
    
    // MARK: - Init
    
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
    
    // MARK: - Private Helpers

    private func startListeningToMonitorStream() async throws {
        let stream: AsyncStream<Void> = await eventsMonitor.listenToMonitorStream()
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
            
            for await _ in stream {
                let bufferedEvents: [NoraiEvent] = await self.buffer.drain()
                guard !bufferedEvents.isEmpty else { continue }
                let processedEvents = await self.processingPipeline.process(events: bufferedEvents)
                guard !processedEvents.isEmpty else { continue }
                await self.dispatch(processedEvents)
            }
        }
    }
    
    private func dispatch(_ events: [NoraiEvent]) async {
        await sendCachedEventsIfAny()
        
        do {
            try await dispatcher.dispatch(events: events)
            try? await cache.clearAll()
        } catch {
            do {
                try await cache.save(events)
                let count = await cache.currentFileEventCount()
                let size = await cache.currentFileSize()
                logger.log("Dispatch failed, cached \(count) events (\(size) bytes)", level: config.logLevel)
            } catch {
                logger.log("Failed to cache events: \(error)", level: config.logLevel)
            }
        }
    }

    private func sendCachedEventsIfAny() async {
        do {
            let cachedEvents = try await cache.loadAll()
            guard !cachedEvents.isEmpty else { return }
            
            logger.log("Sending \(cachedEvents.count) cached events...", level: config.logLevel)
            try await dispatcher.dispatch(events: cachedEvents)
            
            try await cache.clearAll()
            logger.log("Cached events sent and cleared", level: config.logLevel)
        } catch {
            logger.log("Failed to send cached events: \(error)", level: config.logLevel)
        }
    }
}

// MARK: - NoraiEngineProtocol

extension NoraiEngine: NoraiEngineProtocol {
    
    /// Tracks a new event: enriches, caches, and buffers for dispatch
    func track(event: NoraiEvent) async {
        let enrichedEvent = await enrichmentPipeline.enrich(event: event)
        
        // Immediate caching for crash-resilience
        do {
            try await cache.save([enrichedEvent])
        } catch {
            logger.log("Failed to cache event immediately: \(error)", level: config.logLevel)
        }

        await buffer.add(enrichedEvent)
    }
    
    func identify(user context: NoraiUserContext) async {
        await stateManager.update(user: context)
    }

    func start() async throws {
        guard await stateManager.startEngine() else {
            logger.log("Engine already started", level: config.logLevel)
            throw NoraiEngineErrors.alreadyStarted
        }
        
        try await eventsMonitor.startMonitoring()
        try await startListeningToMonitorStream()
    }
}
