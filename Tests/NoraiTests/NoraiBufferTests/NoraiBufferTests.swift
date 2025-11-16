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
    func addEvent() async {
        let sut = makeSUT()
        let testEvent = makeTestEvent()
        await sut.add(testEvent)
        let retrievedEvents = await sut.drain()
        #expect([testEvent] == retrievedEvents)
    }
    
    @Test
    func shouldFlushBelowMaxCount() async {
        let sut = makeSUT()
        for event in Array(repeating: makeTestEvent(),
                           count: 10) {
            await sut.add(event)
        }
        let shouldFlush = await sut.shouldFlush()
        #expect(shouldFlush == false)
    }
    
    @Test
    func shouldFlushAboveMaxCount() async {
        let sut = makeSUT()
        for event in Array(repeating: makeTestEvent(),
                           count: 21) {
            await sut.add(event)
        }
        let shouldFlush = await sut.shouldFlush()
        #expect(shouldFlush == true)
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
