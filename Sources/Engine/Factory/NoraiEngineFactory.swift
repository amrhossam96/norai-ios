//
//  NoraiEngineFactory.swift
//  Norai
//
//  Created by Amr Hossam on 18/11/2025.
//

import Foundation

enum NoraiEngineFactory {
    static func makeEngine(
        with apiKey: String,
        identityManager: NoraiIdentityManagerProtocol,
        sessionManager: NoraiSessionManagerProtocol,
        environment: NoraiEnvironment = .production
    ) -> NoraiEngineProtocol {

        let configuration = NoraiConfiguration(
            apiKey: apiKey,
            environment: environment,
            logLevel: .info
        )

        let logger = NoraiLogger(minimumLevel: configuration.logLevel)

        return NoraiEngine(
            config: configuration,
            logger: logger,
            enrichmentPipeline: NoraiEnrichmentPipeline(
                enrichers: [
                    DeviceMetadataEnricher(),
                    IdentityContextEnricher(identityManager: identityManager),
                    NetworkContextEnricher(networkMonitor: NoraiNetworkMonitor()),
                    SessionEnricher(sessionManager: sessionManager)
            ]),
            processingPipeline: NoraiProcessingPipeline(processors: [
                
            ]),
            eventsMonitor: NoraiEventsMonitor(buffer: NoraiBuffer(),
                                              clock: ContinuousClock()),
            dispatcher: NoraiEventsDispatcher(
                client: NoraiNetworkClient(
                urlSession: URLSession.shared,
                middlewareExecutor: MiddlewareExecutor(middlewares: [
                    AuthenticationMiddleware(projectAPIKey: configuration.apiKey)
                ])
            )),
            cache: NoraiCachingLayer(),
            identityManager: NoraiIdentityManager(encryptedRepo: KeychainWrapper())
        )
    }
}

