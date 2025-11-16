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
    private var isMonitoring: Bool = false
    private let clock: any Clock<Duration>
    private var monitorTask: Task<Void, Never>?
    private let stream: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation
    internal let buffer: NoraiBufferProtocol
    
    init(buffer: NoraiBufferProtocol, clock: any Clock<Duration>) {
        self.buffer = buffer
        self.clock = clock
        (self.stream, self.continuation) = AsyncStream<Void>.makeStream()
    }
    
    deinit {
        monitorTask?.cancel()
        continuation.finish()
    }
    
    private func startPeriodicClock() {
        monitorTask?.cancel()
        monitorTask = Task { [weak self] in
            guard let self else { return }
            
            while await self.isMonitoring {
                do {
                    try await self.clock.sleep(for: .seconds(1))
                    print("[Norai] Tick")
                    
                    if await self.shouldFlush() {
                        await self.updateLastFlushTime()
                        self.continuation.yield()
                    }
                } catch {
                    break
                }
            }
        }
    }
    
    private func updateLastFlushTime() {
        lastFlushingTime = .now
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
}

extension NoraiEventsMonitor: NoraiEventsMonitorProtocol {
    func startMonitoring() async throws {
        guard !isMonitoring else { throw NoraiEventsMonitorErrors.alreadyStarted }
        isMonitoring = true
        lastFlushingTime = .now
        startPeriodicClock()
    }
    
    func stopMonitoring() async {
        isMonitoring = false
        monitorTask?.cancel()
        monitorTask = nil
    }
    
    func listenToMonitorStream() -> AsyncStream<Void> {
        return stream
    }
}
