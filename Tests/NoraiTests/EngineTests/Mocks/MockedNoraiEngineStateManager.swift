//
//  MockedNoraiEngineStateManager.swift
//  Norai
//
//  Created by Amr on 03/07/2025.
//

import Foundation
import Norai

actor MockedNoraiEngineStateManager: NoraiEngineStateManagerProtocol {
    var isStartEngineCalled: Bool = false
    var engineState: NoraiEngineState = NoraiEngineState(isRunning: true, sessionId: UUID())
    var getStateCalled: Bool = false
    var isUpdateCalled: Bool = false

    func startEngine() async throws -> Bool {
        isStartEngineCalled = true
        return isStartEngineCalled
    }
    
    func getState() async -> NoraiEngineState {
        getStateCalled = true
        return engineState
    }
    
    func update(user context: NoraiUserContext) async {
        isUpdateCalled = true
    }
}
