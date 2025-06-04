//
//  NoraiEngine.swift
//  Norai
//
//  Created by Amr on 04/06/2025.
//

import Foundation

public final class NoraiEngine {
    private let processors: [any NoraiEventProcessorProtocol]
    private let dispatcher: any NoraiEventDispatcherProtocol
    private let buffer: any NoraiBufferProtocol
    private var scheduler: any NoraiSchedulerProtocol

    public init(processors: [any NoraiEventProcessorProtocol],
                dispatcher: any NoraiEventDispatcherProtocol,
                buffer: any NoraiBufferProtocol,
                scheduler: any NoraiSchedulerProtocol) {
        self.processors = processors
        self.dispatcher = dispatcher
        self.buffer = buffer
        self.scheduler = scheduler
        self.scheduler.start()
        self.scheduler.delegate = self
    }
    
    private func processEvents(_ events: [NoraiEvent]) -> [NoraiEvent] {
        return processors.reduce(events) { partialResult, processor in
            processor.process(events: partialResult)
        }
    }
    
    deinit { scheduler.stop() }
}

extension NoraiEngine: NoraiEngineProtocol {
    public func track(event: NoraiEvent) async {
        await buffer.add(event)
        await scheduler.eventAdded()
    }
}

extension NoraiEngine: NoraiSchedulerDelegate {
    public func shouldFlush() async {
        let events: [NoraiEvent] = await buffer.drain()
        let processedEvents: [NoraiEvent] = processEvents(events)
        processedEvents.forEach(dispatcher.enqueue)
    }
}
