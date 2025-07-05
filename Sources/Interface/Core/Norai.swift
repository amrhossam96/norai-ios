//
//  Norai.swift
//  Norai
//
//  Created by Amr on 05/07/2025.
//

import Foundation

public protocol NoraiProtocol {
    func configure(with configuration: NoraiConfiguration) async throws
}

@MainActor
public final class Norai {

    //  MARK: - Private Properties

    private var isConfigured: Bool = false
    private var engine: NoraiEngine?

    // MARK: - Singleton
    public static let `default` = Norai()
}

extension Norai: NoraiProtocol {
    public func configure(with configuration: NoraiConfiguration) async throws {
        guard !isConfigured else {
            throw NoraiError.alreadyConfigured
        }
        let engineState = NoraiEngineState()
        let stateManager = NoraiEngineStateManager(state: engineState)
        let buffer = NoraiBuffer()
        let clock = ContinuousClock()
        let cache = NoraiCachingLayer()
        let networkMonitor = NoraiNetworkMonitor()
        let middlewareExecutor = MiddlewareExecutor(middlewares: [])
        let client = NoraiNetworkClient(urlSession: URLSession.shared,
                                        middlewareExecutor: middlewareExecutor)
        let dispatcher = NoraiEventsDispatcher(client: client,
                                               cache: cache,
                                               networkMonitor: networkMonitor)
        let logger = NoraiLogger(currentLevel: configuration.logLevel)
        let eventsMonitor = NoraiEventsMonitor(buffer: buffer,
                                               clock: clock,
                                               logger: logger)
        engine = NoraiEngine(config: configuration,
                             logger: NoraiLogger(currentLevel: configuration.logLevel),
                             stateManager: stateManager,
                             enrichmentPipeline: NoraiEnrichmentPipeline(stateManager: stateManager,
                                                                         enrichers: []),
                             eventsMonitor: eventsMonitor,
                             dispatcher: dispatcher)
        isConfigured = true
        do {
            try await engine?.start()
        } catch {
            print(error)
        }
    }
}
