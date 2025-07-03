//
//  NoraiEventsMonitor.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation

public protocol NoraiEventsMonitorDelegateProtocol: AnyObject, Sendable {
    func shouldFlush() async
}

public enum NoraiEventsMonitorErrors: Error {
    case alreadyStarted
}

public actor NoraiEventsMonitor {
    
    // MARK: - Private

    private weak var delegate: NoraiEventsMonitorDelegateProtocol?
    private var lastFlushingTime: Date?
    private var isTimerOn: Bool = false
    private let clock: any Clock<Duration>
    private var timerTask: Task<Void, Error>?

    // MARK: - Public

    public let buffer: NoraiBufferProtocol

    public init(buffer: NoraiBufferProtocol, clock: any Clock<Duration>) {
        self.buffer = buffer
        self.clock = clock
    }
    
    private func startPeriodicClock() {
        timerTask = Task {
            while isTimerOn {
                try await clock.sleep(for: .seconds(1))
                print("[Norai] - Tick")
            }
        }
        
    }
}

extension NoraiEventsMonitor: NoraiEventsMonitorProtocol {
    public func startMonitoring(with delegate: NoraiEventsMonitorDelegateProtocol) async throws {
        guard !isTimerOn else {
            throw NoraiEventsMonitorErrors.alreadyStarted
        }
        self.delegate = delegate
        isTimerOn = true
        startPeriodicClock()
    }
    
    public func stopMonitoring() async throws {
        timerTask?.cancel()
        timerTask = nil
        isTimerOn = false
    }
}
