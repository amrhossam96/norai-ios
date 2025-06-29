//
//  NoraiEventProcessorProtocol.swift
//  Norai
//
//  Created by Amr on 28/06/2025.
//

import Foundation

public protocol NoraiEventProcessorProtocol {
    func process(event: NoraiEvent) async -> NoraiEvent
}
