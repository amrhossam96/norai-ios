//
//  MockedBuffer.swift
//  Norai
//
//  Created by Amr on 03/07/2025.
//

import Foundation
@testable import Norai

actor MockedBuffer: NoraiBufferProtocol {
    var shouldFlush: Bool = false
    var isAddCalled: Bool = false
    var isDrainCalled: Bool = false
    var events: [NoraiEvent] = []
    var lastAddedEvent: NoraiEvent?

    func add(_ event: NoraiEvent) async {
        isAddCalled = true
        lastAddedEvent = event
        events.append(event)
    }
    
    func drain() async -> [NoraiEvent] {
        isDrainCalled = true
        let drainedEvents = events
        events = []
        return drainedEvents
    }
    
    func shouldFlush() async -> Bool {
        return shouldFlush
    }
    
    func setEvents(_ newEvents: [NoraiEvent]) {
        events = newEvents
    }
}
