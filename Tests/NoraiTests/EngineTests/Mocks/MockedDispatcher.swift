//
//  MockedDispatcher.swift
//  Norai
//
//  Created by Amr on 03/07/2025.
//

import Foundation
import Norai

actor MockedDispatcher: NoraiEventsDispatcherProtocol {
    var isDispatchCalled: Bool = false

    func dispatch(events: [NoraiEvent]) async throws {
        isDispatchCalled = true
    }
}
