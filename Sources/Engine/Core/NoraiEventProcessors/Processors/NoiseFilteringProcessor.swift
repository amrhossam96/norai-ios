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
            guard event.event == "item_viewed",
                  let duration = Double(event.context["viewDuration"] ?? "")
            else { return true }
            if duration < 0.7 {
                return false
            }
            return true
        }
    }
}
