//
//  NoraiEnrichmentPipeline.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation

final class NoraiEnrichmentPipeline: Sendable {
    
    private let enrichers: [any NoraiEventEnricherProtocol]
    init(enrichers: [any NoraiEventEnricherProtocol]) {
        self.enrichers = enrichers
    }
}

extension NoraiEnrichmentPipeline: NoraiEnrichmentPipelineProtocol {
    public func enrich(event: NoraiEvent) async -> NoraiEvent {
        var currentEvent: NoraiEvent = event
        for enricher: any NoraiEventEnricherProtocol in enrichers {
            currentEvent = await enricher.enrich(event: currentEvent)
        }
        return currentEvent
    }
}
