//
//  Norai.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import Foundation

public final class Norai: @unchecked Sendable {
    public static let shared = Norai()
    private var engine: NoraiEngineProtocol?
    
    private init() {
        // Engine starts as nil - requires initialize() to be called
        self.engine = nil
    }
    
    /// Initialize Norai with your API key (required for SDK to work)
    public func initialize(
        apiKey: String,
        environment: NoraiEnvironment = .production,
        logLevel: LogLevel = .info
    ) async throws {
        let config = NoraiConfiguration(
            apiKey: apiKey,
            environment: environment,
            logLevel: logLevel
        )
        
        // Create and start the engine
        let newEngine = Self.createEngine(config: config)
        try await newEngine.start()
        self.engine = newEngine
    }
    
    /// Initialize Norai with just your API key (simplest setup)
    public func initialize(apiKey: String) async throws {
        try await initialize(apiKey: apiKey, environment: .production, logLevel: .info)
    }
    
    // MARK: - Private Engine Creation
    
    /// Creates a fully configured engine with all components
    private static func createEngine(config: NoraiConfiguration) -> NoraiEngine {
        // Core components
        let logger = NoraiLogger(currentLevel: config.logLevel)
        let stateManager = NoraiEngineStateManager(state: NoraiEngineState())
        let buffer = NoraiBuffer()
        let eventsMonitor = NoraiEventsMonitor(
            buffer: buffer,
            clock: ContinuousClock(),
            logger: logger
        )

        let networkMonitor = NoraiNetworkMonitor()
        Task {
            await networkMonitor.startMonitoring()
        }
        
        let middlewareExecutor = MiddlewareExecutor(middlewares: [])
        let networkClient = NoraiNetworkClient(
            urlSession: URLSession.shared,
            middlewareExecutor: middlewareExecutor
        )
        let cache = NoraiCachingLayer()
        let dispatcher = NoraiEventsDispatcher(client: networkClient)
        
        // Create enrichment pipeline with all enrichers
        let enrichers: [any NoraiEventEnricherProtocol] = [
            TimestampEnricher(),
            DeviceMetadataEnricher(),
            ScreenContextEnricher(),
            NetworkContextEnricher(networkMonitor: networkMonitor)
        ]
        
        let enrichmentPipeline = NoraiEnrichmentPipeline(
            stateManager: stateManager,
            enrichers: enrichers
        )
        
        // Create processing pipeline with all processors
        let processors: [any NoraiEventProcessorProtocol] = [
            ViewDurationProcessor(),
            EventFilterProcessor(),
            NoiseFilteringProcessor()
        ]
        
        let processingPipeline = NoraiProcessingPipeline(processors: processors)
        
        // Create fully configured engine
        return NoraiEngine(
            config: config,
            logger: logger,
            stateManager: stateManager,
            enrichmentPipeline: enrichmentPipeline,
            processingPipeline: processingPipeline,
            eventsMonitor: eventsMonitor,
            dispatcher: dispatcher,
            cache: cache
        )
    }
    
    // Engine access removed - developers should only use Norai.shared methods
    
    /// Set current screen context
    public func setCurrentScreen(_ screenName: String) async {
        guard let engine = engine else {
            print("⚠️ Norai not initialized. Call Norai.shared.initialize(apiKey:) first.")
            return
        }
        await engine.track(event: NoraiEvent(
            event: "screen_viewed",
            context: ["screen_name": screenName],
            tags: ["navigation", "screen_view"]
        ))
    }
    
    /// Identify a user
    public func identify(user: NoraiUserContext) async {
        guard let engine = engine else {
            print("⚠️ Norai not initialized. Call Norai.shared.initialize(apiKey:) first.")
            return
        }
        await engine.identify(user: user)
    }
    
    /// Track a custom event
    public func track(event: NoraiEvent) async {
        guard let engine = engine else {
            print("⚠️ Norai not initialized. Call Norai.shared.initialize(apiKey:) first.")
            return
        }
        await engine.track(event: event)
    }
    
    /// Track an event with properties and context (NEW SIMPLE API)
    public func track(
        _ eventName: String,
        properties: [String: String] = [:],
        context: [String: String] = [:]
    ) async {
        let event = NoraiEvent(
            event: eventName,
            properties: properties,
            context: context
        )
        await track(event: event)
    }
}

// MARK: - SwiftUI Extensions

import SwiftUI

extension View {
    /// Track the current screen for analytics
    public func noraiScreen(_ screenName: String) -> some View {
        self.onAppear {
            Task {
                await Norai.shared.setCurrentScreen(screenName)
            }
        }
    }
}
