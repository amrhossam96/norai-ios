//
//  TimestampProcessorTests.swift
//  Norai
//
//  Created by Amr on 04/07/2025.
//

import Foundation
@testable import Norai
import Testing

struct TimestampProcessorTests {
    @Test func timestampProcessor() async throws {
        let sut: TimestampProcessor = TimestampProcessor()
        let date: Date = Date()
        let event: NoraiEvent = await sut.process(event: anyEvent(), timestamp: date)
        #expect(event.timestamp == date)
    }
}


extension TimestampProcessorTests {
    func anyEvent() -> NoraiEvent {
        NoraiEvent(type: EventType.allCases.randomElement()!)
    }
}

