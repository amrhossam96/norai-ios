//
//  MockedEnrichmentPipeline.swift
//  Norai
//
//  Created by Amr on 03/07/2025.
//

import Foundation
@testable import Norai

actor MockedEnrichmentPipeline: NoraiEnrichmentPipelineProtocol {
    var isEnrichCalled: Bool = false
    var lastEnrichedEvent: NoraiEvent?
    var enrichedEvent: NoraiEvent?
    var shouldFail: Bool = false

    func enrich(event: NoraiEvent) async -> NoraiEvent {
        isEnrichCalled = true
        lastEnrichedEvent = event
        
        if shouldFail {
            // In reality, enrichers might fail but we'd handle gracefully
            // For testing, we'll still return the event but mark that failure was simulated
            return event
        }
        
        return enrichedEvent ?? event
    }
    
    func setEnrichedEvent(_ event: NoraiEvent) {
        enrichedEvent = event
    }
    
    func setShouldFail(_ fail: Bool) {
        shouldFail = fail
    }
    
    func setShouldThrowError(_ shouldThrow: Bool) {
        shouldFail = shouldThrow
    }
}
