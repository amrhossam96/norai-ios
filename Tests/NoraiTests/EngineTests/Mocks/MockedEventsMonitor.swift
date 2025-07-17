//
//  MockedEventsMonitor.swift
//  Norai
//
//  Created by Amr on 03/07/2025.
//

import Foundation
@testable import Norai

// Simple mock for basic testing
actor MockedEventsMonitor: NoraiEventsMonitorProtocol {
    
    let buffer: any NoraiBufferProtocol
    var isStartMonitoringCalled: Bool = false
    var isStopMonitoringCalled: Bool = false
    var isListentoMonitorStreamCalled: Bool = false
    private var streamContinuation: AsyncStream<Void>.Continuation?
    
    init(buffer: any NoraiBufferProtocol) {
        self.buffer = buffer
    }
    
    func startMonitoring() async throws {
        isStartMonitoringCalled = true
    }
    
    func stopMonitoring() async throws {
        isStopMonitoringCalled = true
    }
    
    nonisolated func listenToMonitorStream() -> AsyncStream<Void> {
        return AsyncStream<Void> { continuation in
            Task {
                await self.setListenToMonitorStreamCalled()
                await self.setStreamContinuation(continuation)
            }
        }
    }
    
    private func setListenToMonitorStreamCalled() async {
        isListentoMonitorStreamCalled = true
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<Void>.Continuation) {
        streamContinuation = continuation
    }
    
    func triggerStreamSignal() async {
        streamContinuation?.yield()
    }
}

// Real events monitor with TestClock for time-based testing
public actor TestEventsMonitor: NoraiEventsMonitorProtocol {
    public let buffer: any NoraiBufferProtocol
    private let clock: TestClock
    private let logger: any NoraiLoggerProtocol
    private var lastFlushingTime: TestClock.Instant?
    private var isTimerOn: Bool = false
    private var timerTask: Task<Void, Error>?
    private var streamContinuation: AsyncStream<Void>.Continuation?
    
    public init(buffer: any NoraiBufferProtocol, clock: TestClock, logger: any NoraiLoggerProtocol) {
        self.buffer = buffer
        self.clock = clock
        self.logger = logger
    }
    
    public func startMonitoring() async throws {
        guard !isTimerOn else {
            throw NoraiEventsMonitorErrors.alreadyStarted
        }
        isTimerOn = true
        startPeriodicClock()
    }
    
    public func stopMonitoring() async throws {
        timerTask?.cancel()
        timerTask = nil
        isTimerOn = false
        streamContinuation?.finish()
        streamContinuation = nil
    }
    
    nonisolated public func listenToMonitorStream() -> AsyncStream<Void> {
        return AsyncStream<Void> { continuation in
            Task {
                await self.setContinuation(continuation)
                await self.logger.log("🔄 Test stream continuation set up successfully")
            }
        }
    }
    
    private func startPeriodicClock() {
        timerTask = Task {
            await logger.log("📅 Starting test periodic clock...")
            while isTimerOn {
                try await clock.sleep(for: .seconds(1))
                let bufferStatus = await buffer.shouldFlush() ? "FULL" : "NOT_FULL"
                await logger.log("⏰ Test Tick! Buffer: \(bufferStatus)")
                
                if await shouldFlush() {
                    lastFlushingTime = clock.now
                    await logger.log("🚀 Test flushing events! Yielding to stream...")
                    streamContinuation?.yield()
                    await logger.log("✅ Test stream yielded successfully")
                }
            }
            await logger.log("⏹️ Test periodic clock stopped")
        }
    }
    
    private func shouldFlush() async -> Bool {
        let timeSinceLastFlush = shouldFlushBasedOnTime()
        let bufferIsFull = await shouldFlushBasedOnBufferSize()
        let shouldFlushResult = timeSinceLastFlush || bufferIsFull
        
        if shouldFlushResult {
            await logger.log("🔍 Test flush triggered - Time: \(timeSinceLastFlush), Buffer full: \(bufferIsFull)")
        }
        
        return shouldFlushResult
    }
    
    private func shouldFlushBasedOnTime() -> Bool {
        guard let lastFlushingTime = lastFlushingTime else {
            return true
        }
        
        let timeElapsed = lastFlushingTime.duration(to: clock.now)
        return timeElapsed >= .seconds(5) // 5 seconds have passed since last flush
    }
    
    private func shouldFlushBasedOnBufferSize() async -> Bool {
        return await buffer.shouldFlush()
    }
    
    private func setContinuation(_ continuation: AsyncStream<Void>.Continuation) {
        self.streamContinuation = continuation
    }
}
