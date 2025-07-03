//
//  MockedEnrichmentPipeline.swift
//  Norai
//
//  Created by Amr on 03/07/2025.
//

import Foundation
import Norai

actor MockedEnrichmentPipeline: NoraiEnrichmentPipelineProtocol {
    var isEnrichCalled: Bool = false

    func enrich(event: NoraiEvent) async -> NoraiEvent {
        isEnrichCalled = true
        return event
    }
}
