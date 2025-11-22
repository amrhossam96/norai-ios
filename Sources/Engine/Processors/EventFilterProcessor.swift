//
//  EventFilterProcessor.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import Foundation

struct EventFilterProcessor: NoraiEventProcessorProtocol {
    func process(batch: NoraiEventBatch) async -> NoraiEventBatch {
        let filteredEvents = batch.events.filter { _ in true }
        var processedBatch: NoraiEventBatch = batch
        processedBatch.events = filteredEvents
        return processedBatch
    }
} 




