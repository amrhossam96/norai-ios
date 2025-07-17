//
//  NoraiProcessingPipeline.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import Foundation

public final class NoraiProcessingPipeline: @unchecked Sendable {
    private let processors: [any NoraiEventProcessorProtocol]
    
    public init(processors: [any NoraiEventProcessorProtocol]) {
        self.processors = processors
    }
}

extension NoraiProcessingPipeline: NoraiProcessingPipelineProtocol {
    public func process(events: [NoraiEvent]) async -> [NoraiEvent] {
        var currentEvents: [NoraiEvent] = events
        
        // Run each processor sequentially on the event batch
        for processor in processors {
            currentEvents = await processor.process(events: currentEvents)
        }
        
        return currentEvents
    }
} 