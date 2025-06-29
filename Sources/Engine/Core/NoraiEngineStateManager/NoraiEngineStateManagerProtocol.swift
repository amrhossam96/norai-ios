//
//  NoraiEngineStateManagerProtocol.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation

public protocol NoraiEngineStateManagerProtocol {
    func startEngine() async throws
    func getState() async -> NoraiEngineState
    func update(user context: NoraiUserContext) async
    
}
