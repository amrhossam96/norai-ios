//
//  MockedProcessingPipeline.swift
//  Norai
//
//  Created by Amr on 28/06/2025.
//

import Foundation
@testable import Norai

public actor MockedProcessingPipeline: NoraiProcessingPipelineProtocol {
    public var isProcessCalled: Bool = false
    public var processedEvents: [NoraiEvent] = []
    private var eventsToReturn: [NoraiEvent]?
    
    public init() {}
    
    public func process(events: [NoraiEvent]) async -> [NoraiEvent] {
        isProcessCalled = true
        processedEvents = events
        return eventsToReturn ?? events // Return configured events or original events
    }
    
    public func setProcessedEvents(_ events: [NoraiEvent]) {
        eventsToReturn = events
    }
} 