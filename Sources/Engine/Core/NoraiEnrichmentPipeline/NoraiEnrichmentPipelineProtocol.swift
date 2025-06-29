//
//  NoraiEnrichmentPipelineProtocol.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation

public protocol NoraiEnrichmentPipelineProtocol {
    func enrich(event: NoraiEvent) async -> NoraiEvent
}
