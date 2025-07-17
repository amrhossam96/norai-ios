//
//  MockedDispatcher.swift
//  Norai
//
//  Created by Amr on 03/07/2025.
//

import Foundation
import Norai

enum MockedDispatcherError: Error {
    case simulatedFailure
}

actor MockedDispatcher: NoraiEventsDispatcherProtocol {
    var isDispatchCalled: Bool = false
    var lastDispatchedEvents: [NoraiEvent]?
    var shouldFail: Bool = false

    func dispatch(events: [NoraiEvent]) async throws {
        isDispatchCalled = true
        lastDispatchedEvents = events
        
        if shouldFail {
            throw MockedDispatcherError.simulatedFailure
        }
    }
    
    func setShouldFail(_ fail: Bool) {
        shouldFail = fail
    }
}
