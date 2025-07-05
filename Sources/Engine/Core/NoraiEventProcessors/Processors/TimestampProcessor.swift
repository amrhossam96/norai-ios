//
//  TimestampProcessor.swift
//  Norai
//
//  Created by Amr on 28/06/2025.
//

import Foundation

public struct TimestampProcessor: NoraiEventProcessorProtocol {
    public func process(event: NoraiEvent, timestamp: Date) async -> NoraiEvent {
        var eventCopy = event
        eventCopy.timestamp = timestamp
        return eventCopy
    }
}
