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
    
    public init() {}
    
    public func process(events: [NoraiEvent]) async -> [NoraiEvent] {
        isProcessCalled = true
        processedEvents = events
        return events // Return events unchanged for testing
    }
} 