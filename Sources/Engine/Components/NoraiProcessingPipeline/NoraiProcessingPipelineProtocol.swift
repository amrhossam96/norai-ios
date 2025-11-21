//
//  NoraiProcessingPipelineProtocol.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import Foundation

protocol NoraiProcessingPipelineProtocol: Sendable {
    func process(batch: NoraiEventBatch) async -> NoraiEventBatch
}
