//
//  NoiseFilteringProcessor.swift
//  Norai
//
//  Created by Amr Hossam on 21/07/2025.
//

import Foundation

struct NoiseFilteringProcessor: NoraiEventProcessorProtocol {
    func process(events: [NoraiEvent]) async -> [NoraiEvent] {
        return events.filter { event in            
            return true
        }
    }
}
