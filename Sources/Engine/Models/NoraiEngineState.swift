//
//  NoraiEngineState.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation

public struct NoraiEngineState: Sendable {
    var isRunning: Bool
    var sessionId: UUID
    var lastScreen: String?
    var funnelStep: String?
    var userContext: NoraiUserContext?
    
    public init(
        isRunning: Bool,
        sessionId: UUID,
        lastScreen: String? = nil,
        funnelStep: String? = nil,
        userContext: NoraiUserContext? = nil
    ) {
        self.isRunning = isRunning
        self.sessionId = sessionId
        self.lastScreen = lastScreen
        self.funnelStep = funnelStep
        self.userContext = userContext
    }
}
