//
//  EventFilterProcessor.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import Foundation

public struct EventFilterProcessor: NoraiEventProcessorProtocol {
    public init() {}
    
    public func process(events: [NoraiEvent]) async -> [NoraiEvent] {
        // Filter out suppressed events
        return events.filter { event in
            !event.tags.contains("suppressed")
        }
    }
} 