//
//  NoraiEventProcessorProtocol.swift
//  Norai
//
//  Created by Amr on 28/06/2025.
//

import Foundation

protocol NoraiEventProcessorProtocol {
    func process(events: [NoraiEvent]) async -> [NoraiEvent]
}

