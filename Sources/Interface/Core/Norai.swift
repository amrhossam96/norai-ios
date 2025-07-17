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
    
    private init() {}
    
    /// Initialize Norai with complete analytics pipeline
    public func initialize(
        apiKey: String,
        environment: NoraiEnvironment = .staging,
        logLevel: LogLevel = .debug
    ) async throws {
        // Configuration
        let config = NoraiConfiguration(
            apiKey: apiKey,
            environment: environment,
            logLevel: logLevel
        )
        
        // Core components
        let logger = NoraiLogger(currentLevel: logLevel)
        let stateManager = NoraiEngineStateManager(state: NoraiEngineState())
        let buffer = NoraiBuffer()
        let eventsMonitor = NoraiEventsMonitor(
            buffer: buffer,
            clock: ContinuousClock(),
            logger: logger
        )
        
        // Network components
        let networkMonitor = NoraiNetworkMonitor()
        let middlewareExecutor = MiddlewareExecutor(middlewares: [])
        let networkClient = NoraiNetworkClient(
            urlSession: URLSession.shared,
            middlewareExecutor: middlewareExecutor
        )
        let cache = NoraiCachingLayer()
        let dispatcher = NoraiEventsDispatcher(
            client: networkClient,
            cache: cache,
            networkMonitor: networkMonitor
        )
        
        // 🎯 CREATE ENRICHMENT PIPELINE WITH ALL ENRICHERS
        let enrichers: [any NoraiEventEnricherProtocol] = [
            UserContextEnricher(),
            DeviceMetadataEnricher(),
            ScreenContextEnricher(),
            NetworkContextEnricher(networkMonitor: networkMonitor)
        ]
        
        let enrichmentPipeline = NoraiEnrichmentPipeline(
            stateManager: stateManager,
            enrichers: enrichers
        )
        
        // Initialize engine
        self.engine = NoraiEngine(
            config: config,
            logger: logger,
            stateManager: stateManager,
            enrichmentPipeline: enrichmentPipeline,
            eventsMonitor: eventsMonitor,
            dispatcher: dispatcher
        )
        
        // Start the engine
        try await engine?.start()
    }
    
    /// Get the initialized engine for use in components
    public func getEngine() -> NoraiEngineProtocol? {
        return engine
    }
    
    /// Set current screen context
    public func setCurrentScreen(_ screenName: String) async {
        await engine?.track(event: NoraiEvent(
            type: .screenViewed,
            context: EventContext(screen: screenName),
            tags: ["navigation", "screen_view"]
        ))
    }
    
    /// Identify a user
    public func identify(user: NoraiUserContext) async {
        await engine?.identify(user: user)
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
