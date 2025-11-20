//
//  NoraiEnrichmentPipelineProtocol.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation

protocol NoraiEnrichmentPipelineProtocol: Sendable {
    func enrich(event: NoraiEvent) async -> NoraiEvent
}
