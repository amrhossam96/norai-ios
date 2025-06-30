//
//  NoraiBuffer.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation

public actor NoraiBuffer {
    private var events: [NoraiEvent] = []
}

extension NoraiBuffer: NoraiBufferProtocol {
    public func add(_ event: NoraiEvent) {
        events.append(event)
    }
    
    public func drain() -> [NoraiEvent] {
        defer { events = [] }
        let drainedEvents: [NoraiEvent] = events
        return drainedEvents
    }
}
