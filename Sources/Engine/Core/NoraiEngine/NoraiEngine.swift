//
//  NoraiEngine.swift
//  Norai
//
//  Created by Amr on 28/06/2025.
//

import Foundation

public final class NoraiEngine {
    private let config: NoraiConfiguration
    private var logger: any NoraiLoggerProtocol
    
    private let stateManager: any NoraiEngineStateManagerProtocol
    private var enrichmentPipeline: any NoraiEnrichmentPipelineProtocol

    public init(
        config: NoraiConfiguration,
        logger: any NoraiLoggerProtocol,
        stateManager: any NoraiEngineStateManagerProtocol,
        enrichmentPipeline: any NoraiEnrichmentPipelineProtocol
    ) {
        self.config = config
        self.logger = logger
        self.stateManager = stateManager
        self.enrichmentPipeline = enrichmentPipeline
    }
}

extension NoraiEngine: NoraiEngineProtocol {
    public func track(event: NoraiEvent) async {
        let enrichedEvent = await enrichmentPipeline.enrich(event: event)
        logger.log(enrichedEvent, level: config.logLevel)
    }
    
    public func identify(user context: NoraiUserContext) async {
        await stateManager.update(user: context)
    }
    
    public func start() async {
        do {
          try await stateManager.startEngine()
        } catch {
            self.logger.log(error, level: config.logLevel)
        }
    }
}
