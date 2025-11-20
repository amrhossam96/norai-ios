//
//  NoraiEventEnricherProtocol.swift
//  Norai
//
//  Created by Amr on 28/06/2025.
//

import Foundation

protocol NoraiEventEnricherProtocol: Sendable {
    func enrich(event: NoraiEvent) async -> NoraiEvent
}

