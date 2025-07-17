//
//  NoraiProcessingPipelineProtocol.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import Foundation

public protocol NoraiProcessingPipelineProtocol: Sendable {
    func process(events: [NoraiEvent]) async -> [NoraiEvent]
} 