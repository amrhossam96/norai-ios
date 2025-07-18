//
//  MockedNoraiEngineStateManager.swift
//  Norai
//
//  Created by Amr on 03/07/2025.
//

import Foundation
@testable import Norai

enum MockedNoraiEngineStateManagerMessages {
    case startEngine
}

actor MockedNoraiEngineStateManager: NoraiEngineStateManagerProtocol {
    var startEngineMessages: [MockedNoraiEngineStateManagerMessages] = []
    var engineState: NoraiEngineState = NoraiEngineState(isRunning: true, sessionId: UUID())
    var getStateCalled: Bool = false
    var isUpdateCalled: Bool = false
    var capturedUserContext: NoraiUserContext?
    var lastUserContext: NoraiUserContext?

    func startEngine() async -> Bool {
        startEngineMessages.append(.startEngine)
        return startEngineMessages.count == 1
    }
    
    func getState() async -> NoraiEngineState {
        getStateCalled = true
        return engineState
    }
    
    func update(user context: NoraiUserContext) async {
        capturedUserContext = context
        lastUserContext = context
        isUpdateCalled = true
    }
}
