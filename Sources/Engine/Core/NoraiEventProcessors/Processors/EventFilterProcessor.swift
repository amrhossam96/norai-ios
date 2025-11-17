//
//  EventFilterProcessor.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import Foundation

struct EventFilterProcessor: NoraiEventProcessorProtocol {
    func process(events: [NoraiEvent]) async -> [NoraiEvent] {
        
        return events.filter { event in
            return true
        }
    }
} 
