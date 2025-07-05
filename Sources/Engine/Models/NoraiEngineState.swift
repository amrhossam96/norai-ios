//
//  NoraiEngineState.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation

public struct NoraiEngineState: Sendable {
    public var isRunning: Bool
    public var sessionId: UUID
    public var lastScreen: String?
    public var funnelStep: String?
    public var userContext: NoraiUserContext?
    
    public init(
        isRunning: Bool = false,
        sessionId: UUID = UUID(),
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
