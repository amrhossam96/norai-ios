//
//  NoraiProcessingPipeline.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import Foundation

final class NoraiProcessingPipeline: @unchecked Sendable {
    private let processors: [any NoraiEventProcessorProtocol]
    
    public init(processors: [any NoraiEventProcessorProtocol]) {
        self.processors = processors
    }
}

extension NoraiProcessingPipeline: NoraiProcessingPipelineProtocol {
    public func process(batch: NoraiEventBatch) async -> NoraiEventBatch {
        var processedBatch: NoraiEventBatch = batch
        
        for processor in processors {
            processedBatch = await processor.process(batch: processedBatch)
        }
        
        return processedBatch
    }
} 
