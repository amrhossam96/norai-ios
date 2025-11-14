//
//  NoraiEventEnricherProtocol.swift
//  Norai
//
//  Created by Amr on 28/06/2025.
//

import Foundation

public protocol NoraiEventEnricherProtocol: Sendable {
    func enrich(event: NoraiEvent, with state: NoraiEngineState) async -> NoraiEvent
}
