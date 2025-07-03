//
//  NoraiEventsMonitor.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation

public protocol NoraiEventsMonitorDelegateProtocol: AnyObject {
    func shouldFlush() async
}

public enum NoraiEventsMonitorErrors: Error {
    case alreadyStarted
}

public class NoraiEventsMonitor {
    
    // MARK: - Private

    private weak var delegate: NoraiEventsMonitorDelegateProtocol?
    private var lastFlushingTime: Date?
    private var isTimerOn: Bool = false
    private let clock: any Clock<Duration>

    // MARK: - Public

    public let buffer: NoraiBufferProtocol

    public init(buffer: NoraiBufferProtocol, clock: any Clock<Duration>) {
        self.buffer = buffer
        self.clock = clock
    }
    
    private func startPeriodicClock() async throws {
        while isTimerOn {
            try await clock.sleep(for: .seconds(1))
            print("[Norai] - Tick")
        }
        
    }
}

extension NoraiEventsMonitor: NoraiEventsMonitorProtocol {
    public func startMonitoring(with delegate: NoraiEventsMonitorDelegateProtocol) async throws {
        guard !isTimerOn else {
            throw NoraiEventsMonitorErrors.alreadyStarted
        }
        self.delegate = delegate
        try await startPeriodicClock()
        isTimerOn = true
    }
}

extension Clock {
    public func sleep(for duration: Duration, tolerance: Duration? = nil) async throws {
        try await self.sleep(until: self.now.advanced(by: duration), tolerance: tolerance)
    }
}
