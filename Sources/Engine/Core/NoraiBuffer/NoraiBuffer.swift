//
//  NoraiBuffer.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation

enum NoraiBufferPolicy {
    static let maxEventsCount: Int = 20
}

actor NoraiBuffer {
    private var events: [NoraiEvent]
    init(events: [NoraiEvent] = []) {
        self.events = events
    }
}

extension NoraiBuffer: NoraiBufferProtocol {
    func add(_ event: NoraiEvent) async {
        events.append(event)
    }
    
    func drain() async -> [NoraiEvent] {
        defer { events = [] }
        let drainedEvents: [NoraiEvent] = events
        return drainedEvents
    }
    
    func shouldFlush() async -> Bool {
        return events.count >= NoraiBufferPolicy.maxEventsCount
    }
}
