//
//  NoiseFilteringProcessor.swift
//  Norai
//
//  Created by Amr Hossam on 21/07/2025.
//

import Foundation

struct NoiseFilteringProcessor: NoraiEventProcessorProtocol {

    func process(batch: NoraiEventBatch) async -> NoraiEventBatch {
        var kept: [NoraiEvent] = []
        for event in batch.events where shouldKeep(event, after: kept.last) {
            kept.append(event)
        }

        var result = batch
        result.events = kept
        return result
    }

    private func shouldKeep(_ event: NoraiEvent, after last: NoraiEvent?) -> Bool {
        guard let last else { return true }
        let sameType = (last.eventType == event.eventType)
        let delta = event.createdAt.timeIntervalSince(last.createdAt)
        let tooClose = delta >= 0 && delta < 0.150
        if sameType && tooClose {
            return false
        }

        return true
    }
}






