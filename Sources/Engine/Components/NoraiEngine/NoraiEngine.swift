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

actor NoraiEngine {
    
    // MARK: - Dependencies
    
    private let config: NoraiConfiguration
    private let logger: any NoraiLoggerProtocol
    private let enrichmentPipeline: any NoraiEnrichmentPipelineProtocol
    private let processingPipeline: any NoraiProcessingPipelineProtocol
    private let eventsMonitor: any NoraiEventsMonitorProtocol
    private let buffer: any NoraiBufferProtocol
    private let dispatcher: any NoraiEventsDispatcherProtocol
    private let cache: any NoraiCachingLayerProtocol
    private let identityManager: any NoraiIdentityManagerProtocol
    
    // MARK: - Private Task
    
    private var monitorListenerTask: Task<Void, Never>?

    // MARK: - Init
    
    init(
        config: NoraiConfiguration,
        logger: any NoraiLoggerProtocol,
        enrichmentPipeline: any NoraiEnrichmentPipelineProtocol,
        processingPipeline: any NoraiProcessingPipelineProtocol,
        eventsMonitor: any NoraiEventsMonitorProtocol,
        dispatcher: any NoraiEventsDispatcherProtocol,
        cache: any NoraiCachingLayerProtocol,
        identityManager: any NoraiIdentityManagerProtocol
    ) {
        self.config = config
        self.logger = logger
        self.enrichmentPipeline = enrichmentPipeline
        self.processingPipeline = processingPipeline
        self.eventsMonitor = eventsMonitor
        self.buffer = eventsMonitor.buffer
        self.dispatcher = dispatcher
        self.cache = cache
        self.identityManager = identityManager
    }
    
    // MARK: - Private Helpers

    private func startListeningToMonitorStream() {
        monitorListenerTask?.cancel()
        monitorListenerTask = Task { [weak self] in
            guard let self else { return }
            let stream = await self.eventsMonitor.listenToMonitorStream()
            
            for await _ in stream {
                let bufferedEvents = await self.buffer.drain()
                guard !bufferedEvents.isEmpty else { continue }
                let batch = NoraiEventBatch(events: bufferedEvents, metaData: [:])
                let processedBatch = await self.processingPipeline.process(batch: batch)
                guard !processedBatch.events.isEmpty else { continue }
                await self.dispatch(processedBatch)
            }
        }
    }
    
    private func cache(_ batch: NoraiEventBatch) async {
        do {
            try await cache.save(batch)
            let count = await cache.currentFileBatchCount()
            let size = await cache.currentFileSize()
            logger.log("Dispatch failed, cached batch with \(batch.events.count) events (total: \(count) batches, \(size) bytes)", level: config.logLevel)
        } catch {
            logger.log("Failed to cache events: \(error)", level: config.logLevel)
        }
    }
    
    private func dispatch(_ batch: NoraiEventBatch) async {
        await sendCachedEventsBatchesIfAny()
        
        do {
            let result = try await dispatcher.dispatch(eventsBatch: batch)
            guard result.sucess else {
                await cache(batch)
                return
            }
        } catch {
            await cache(batch)
        }
    }

    private func sendCachedEventsBatchesIfAny() async {
        do {
            let cachedBatches: [NoraiEventBatch] = try await cache.loadAll()
            guard !cachedBatches.isEmpty else { return }

            logger.log("Sending \(cachedBatches.count) cached events batches...", level: config.logLevel)

            var failedBatches: [NoraiEventBatch] = []
            
            await withTaskGroup(of: NoraiEventBatch?.self) { group in
                for batch in cachedBatches {
                    group.addTask { [weak self] in
                        guard let self else { return batch }
                        do {
                            let result = try await dispatcher.dispatch(eventsBatch: batch)
                            return result.sucess ? nil : batch
                        } catch {
                            logger.log("Failed to dispatch batch: \(error)", level: config.logLevel)
                            return batch
                        }
                    }
                }
                
                for await failedBatch in group {
                    if let failedBatch = failedBatch {
                        failedBatches.append(failedBatch)
                    }
                }
            }

            try await cache.clearAll()
            for batch in failedBatches {
                do {
                    try await cache.save(batch)
                } catch {
                    logger.log("Failed to re-cache failed batch: \(error)", level: config.logLevel)
                }
            }

            if failedBatches.isEmpty {
                logger.log("Cached events sent and cleared", level: config.logLevel)
            } else {
                logger.log("\(failedBatches.count) batches failed to send and were re-cached", level: config.logLevel)
            }
        } catch {
            logger.log("Failed to send cached events: \(error)", level: config.logLevel)
        }
    }

}

// MARK: - NoraiEngineProtocol

extension NoraiEngine: NoraiEngineProtocol {
    func start() async {
        do {
            try await eventsMonitor.startMonitoring()
            startListeningToMonitorStream()
            await sendCachedEventsBatchesIfAny()
        } catch {
            logger.log("Couldn't start engine", level: config.logLevel)
        }
    }
    
    func identify(userID: String) async {
        await identityManager.identify(userID: userID)
        let identity = await identityManager.currentIdentity()
        let anonymousID = identity.anonymousID
        guard let userID = identity.userID else { return }
        let identityPayload = NoraiUserIdentity(userID: userID, anonymousID: anonymousID)
        do {
            let result = try await dispatcher.syncIdentity(payload: identityPayload)
            if result.success {
                logger.log("User identity is synced.", level: config.logLevel)
            }
        } catch {
            logger.log("Identification syncing failed.", level: config.logLevel)
        }
    }
    
    func trackEvent(name: String, properties: [String : JSONValue]) async {
        Task {
            let event = NoraiEvent(eventType: name,
                                   properties: properties,
                                   context: [:])
            let enrichedEvent = await enrichmentPipeline.enrich(event: event)
            await buffer.add(enrichedEvent)
        }
    }
}
