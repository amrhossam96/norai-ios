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
    var engineState: NoraiEngineState = NoraiEngineState(isRunning: false, sessionId: UUID())
    var getStateCalled: Bool = false
    var isUpdateCalled: Bool = false
    var capturedUserContext: NoraiUserContext?
    var lastUserContext: NoraiUserContext?
    
    // Additional properties for test compatibility
    var isStartCalled: Bool = false
    var currentState: NoraiEngineState { engineState }

    func startEngine() async -> Bool {
        startEngineMessages.append(.startEngine)
        isStartCalled = true
        
        // If already running, return false
        if engineState.isRunning {
            return false
        }
        
        // Start the engine
        engineState = NoraiEngineState(isRunning: true, sessionId: engineState.sessionId, lastScreen: engineState.lastScreen, userContext: engineState.userContext)
        return true
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
    
    // Additional helper method for tests
    func updateEngineState(_ update: (inout NoraiEngineState) -> Void) async {
        var mutableState = engineState
        update(&mutableState)
        engineState = mutableState
    }
}
