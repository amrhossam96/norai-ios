//
//  NoraiBuffer.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation

public actor NoraiBuffer {
    private var events: [NoraiEvent]
    public init(events: [NoraiEvent] = []) {
        self.events = events
    }
}

extension NoraiBuffer: NoraiBufferProtocol {
    public func add(_ event: NoraiEvent) async {
        events.append(event)
    }
    
    public func drain() async -> [NoraiEvent] {
        defer { events = [] }
        let drainedEvents: [NoraiEvent] = events
        return drainedEvents
    }
    
    public func shouldFlush() async -> Bool {
        return events.count >= 3  // Reduced from 20 to 3 for easier testing
    }
}
