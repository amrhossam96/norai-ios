//
//  NoraiEnrichmentPipeline.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation

public final class NoraiEnrichmentPipeline {
    private let stateManager: NoraiEngineStateManagerProtocol
    private let enrichers: [any NoraiEventEnricherProtocol]
    public init(stateManager: NoraiEngineStateManagerProtocol, enrichers: [any NoraiEventEnricherProtocol]) {
        self.stateManager = stateManager
        self.enrichers = enrichers
    }
}

extension NoraiEnrichmentPipeline: NoraiEnrichmentPipelineProtocol {
    public func enrich(event: NoraiEvent) async -> NoraiEvent {
        let state = await stateManager.getState()
        var currentEvent = event
        for enricher in enrichers {
            currentEvent = await enricher.enrich(event: currentEvent, with: state)
        }
        return currentEvent
    }
}
