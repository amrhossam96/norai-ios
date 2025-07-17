//
//  NoraiEventsMonitor.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation

public enum NoraiEventsMonitorErrors: Error {
    case alreadyStarted
}

public actor NoraiEventsMonitor {
    
    // MARK: - Private

    private var lastFlushingTime: Date?
    private var isTimerOn: Bool = false
    private let clock: any Clock<Duration>
    private var timerTask: Task<Void, Error>?
    private var streamContinuation: AsyncStream<Void>.Continuation?
    private var logger: NoraiLoggerProtocol
    // MARK: - Public

    public let buffer: NoraiBufferProtocol

    public init(buffer: NoraiBufferProtocol, clock: any Clock<Duration>, logger: NoraiLoggerProtocol) {
        self.buffer = buffer
        self.clock = clock
        self.logger = logger
    }
    
    private func startPeriodicClock() {
        timerTask = Task {
            await logger.log("📅 Starting periodic clock...")
            while isTimerOn {
                try await clock.sleep(for: .seconds(1))
                let bufferStatus = await buffer.shouldFlush() ? "FULL" : "NOT_FULL"
                await logger.log("⏰ Tick! Buffer: \(bufferStatus)")
                
                if await shouldFlush() {
                    lastFlushingTime = .now
                    await logger.log("🚀 Flushing events! Yielding to stream...")
                    streamContinuation?.yield()
                    await logger.log("✅ Stream yielded at \(lastFlushingTime?.description ?? "")")
                }
            }
            await logger.log("⏹️ Periodic clock stopped")
        }
    }
    
    private func shouldFlush() async -> Bool {
        let timeSinceLastFlush = shouldFlushBasedOnTime()
        let bufferIsFull = await shouldFlushBasedOnBufferSize()
        let shouldFlushResult = timeSinceLastFlush || bufferIsFull
        
        if shouldFlushResult {
            await logger.log("🔍 Flush triggered - Time: \(timeSinceLastFlush), Buffer full: \(bufferIsFull)")
        }
        
        return shouldFlushResult
    }
    
    private func shouldFlushBasedOnTime() -> Bool {
        guard let lastFlushingTime = lastFlushingTime else {
            return true
        }
        
        return Date().timeIntervalSince(lastFlushingTime) >= 5.0  // Reduced from 20s to 5s for testing
    }
    
    private func shouldFlushBasedOnBufferSize() async -> Bool {
        return await buffer.shouldFlush()
    }
    
    private func setContinution(_ continuation: AsyncStream<Void>.Continuation) {
        self.streamContinuation = continuation
    }
}

extension NoraiEventsMonitor: NoraiEventsMonitorProtocol {
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
                await self.setContinution(continuation)
                await self.logger.log("🔄 Stream continuation set up successfully")
            }
        }
    }
}
