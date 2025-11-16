//
//  NoraiBufferTests.swift
//  Norai
//
//  Created by Amr Hossam on 16/11/2025.
//

import Testing
import Norai

struct NoraiBufferTests {

    @Test
    func testAddEvent() async {
        let sut = makeSUT()
        let testEvent = makeTestEvent()
        await sut.add(testEvent)
        let retrievedEvents = await sut.drain()
        #expect([testEvent] == retrievedEvents)
    }
}



extension NoraiBufferTests {
    func makeSUT() -> NoraiBufferProtocol {
        return NoraiBuffer()
    }
    
    func makeTestEvent() -> NoraiEvent {
        return NoraiEvent(event: "item_view")
    }
}
