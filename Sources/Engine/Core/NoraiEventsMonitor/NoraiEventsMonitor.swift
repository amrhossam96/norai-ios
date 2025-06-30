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
    // MARK: - Public

    public let buffer: NoraiBufferProtocol

    init(buffer: NoraiBufferProtocol) {
        self.buffer = buffer
    }
    
    private func startPeriodicClock() async throws {
        let clock = ContinuousClock()
        while isTimerOn {
            try await clock.sleep(until: .now.advanced(by: .seconds(1)))
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
