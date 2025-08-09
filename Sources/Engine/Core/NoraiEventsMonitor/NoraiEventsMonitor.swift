//
//  NoraiEventsMonitor.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation

enum NoraiEventsMonitorErrors: Error {
    case alreadyStarted
}

actor NoraiEventsMonitor {
    
    // MARK: - Private

    private var lastFlushingTime: Date?
    private var isTimerOn: Bool = false
    private let clock: any Clock<Duration>
    private var timerTask: Task<Void, Error>?
    private var streamContinuation: AsyncStream<Void>.Continuation?
    private var logger: NoraiLoggerProtocol
    // MARK: - Internal

    let buffer: NoraiBufferProtocol

    init(buffer: NoraiBufferProtocol, clock: any Clock<Duration>, logger: NoraiLoggerProtocol) {
        self.buffer = buffer
        self.clock = clock
        self.logger = logger
    }
    
    private func startPeriodicClock() {
        timerTask = Task {
            while isTimerOn {
                try await clock.sleep(for: .seconds(1))
//                print("tick")
                if await shouldFlush() {
                    lastFlushingTime = .now
                    streamContinuation?.yield()
                }
            }
        }
    }
    
    private func shouldFlush() async -> Bool {
        let timeSinceLastFlush = shouldFlushBasedOnTime()
        let bufferIsFull = await shouldFlushBasedOnBufferSize()
        return timeSinceLastFlush || bufferIsFull
    }
    
    private func shouldFlushBasedOnTime() -> Bool {
        guard let lastFlushingTime = lastFlushingTime else {
            return true
        }
        
        return Date().timeIntervalSince(lastFlushingTime) >= 30.0
    }
    
    private func shouldFlushBasedOnBufferSize() async -> Bool {
        return await buffer.shouldFlush()
    }
    
    private func setContinution(_ continuation: AsyncStream<Void>.Continuation) {
        self.streamContinuation = continuation
    }
}

extension NoraiEventsMonitor: NoraiEventsMonitorProtocol {
    func startMonitoring() async throws {
        guard !isTimerOn else {
            throw NoraiEventsMonitorErrors.alreadyStarted
        }
        isTimerOn = true
        startPeriodicClock()
    }
    
    func stopMonitoring() async throws {
        timerTask?.cancel()
        timerTask = nil
        isTimerOn = false
        streamContinuation?.finish()
        streamContinuation = nil
    }
    
    func listenToMonitorStream() async -> AsyncStream<Void> {
        return AsyncStream<Void> { continuation in
            self.setContinution(continuation)
        }
    }
}
