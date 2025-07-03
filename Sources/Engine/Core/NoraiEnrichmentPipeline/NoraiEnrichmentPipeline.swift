//
//  NoraiEnrichmentPipeline.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation

public final class NoraiEnrichmentPipeline: @unchecked Sendable {
    private let stateManager: NoraiEngineStateManagerProtocol
    private let enrichers: [any NoraiEventEnricherProtocol]
    public init(stateManager: NoraiEngineStateManagerProtocol, enrichers: [any NoraiEventEnricherProtocol]) {
        self.stateManager = stateManager
        self.enrichers = enrichers
    }
}

extension NoraiEnrichmentPipeline: NoraiEnrichmentPipelineProtocol {
    public func enrich(event: NoraiEvent) async -> NoraiEvent {
        let state: NoraiEngineState = await stateManager.getState()
        var currentEvent: NoraiEvent = event
        for enricher: any NoraiEventEnricherProtocol in enrichers {
            currentEvent = await enricher.enrich(event: currentEvent, with: state)
        }
        return currentEvent
    }
}
