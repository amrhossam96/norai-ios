//
//  NoraiEngineStateManagerProtocol.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation

public protocol NoraiEngineStateManagerProtocol: Sendable {
    func startEngine() async -> Bool
    func getState() async -> NoraiEngineState
    func update(user context: NoraiUserContext) async
    
}
