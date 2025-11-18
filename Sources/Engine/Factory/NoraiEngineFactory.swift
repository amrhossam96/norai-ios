//
//  NoraiEngineFactory.swift
//  Norai
//
//  Created by Amr Hossam on 18/11/2025.
//

import Foundation

enum NoraiEngineFactory {
    static func makeEngine(with apiKey: String) -> NoraiEngineProtocol {
        let configuration = NoraiConfiguration(
            apiKey: apiKey,
            environment: .production,
            logLevel: .info
        )
        
        let logger = NoraiLogger(minimumLevel: configuration.logLevel)
        
        return NoraiEngine(
            config: configuration,
            logger: logger,
            enrichmentPipeline: NoraiEnrichmentPipeline(enrichers: []),
            processingPipeline: NoraiProcessingPipeline(processors: []),
            eventsMonitor: NoraiEventsMonitor(buffer: NoraiBuffer(),
                                              clock: ContinuousClock()),
            dispatcher: NoraiEventsDispatcher(
                client: NoraiNetworkClient(
                    urlSession: URLSession.shared,
                    middlewareExecutor: MiddlewareExecutor(middlewares: [])
                )
            ),
            cache: NoraiCachingLayer()
        )
    }
}
