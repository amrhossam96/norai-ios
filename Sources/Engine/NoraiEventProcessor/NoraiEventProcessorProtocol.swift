//
//  NoraiEventProcessorProtocol.swift
//  Norai
//
//  Created by Amr on 04/06/2025.
//

import Foundation

public protocol NoraiEventProcessorProtocol {
    func process(events: [NoraiEvent]) -> [NoraiEvent]
}
