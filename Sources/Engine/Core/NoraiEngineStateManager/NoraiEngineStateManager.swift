//
//  NoraiEngineStateManager.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation

public enum NoraiEngineStateManagerErrors: Error {
    case alreadyRunning
}

public actor NoraiEngineStateManager {
    private var state: NoraiEngineState
    
    public init(state: NoraiEngineState) {
        self.state = state
    }
}

extension NoraiEngineStateManager: NoraiEngineStateManagerProtocol {
    public func startEngine() async throws -> Bool {
        guard !state.isRunning else {
            throw NoraiEngineStateManagerErrors.alreadyRunning
        }
        self.state.isRunning = true
        return state.isRunning
    }

    public func getState() -> NoraiEngineState {
        return state
    }
    
    public func update(user context: NoraiUserContext) {
        state.userContext = context
    }
}
