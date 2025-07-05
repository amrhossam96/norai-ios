//
//  MockedEventsMonitor.swift
//  Norai
//
//  Created by Amr on 03/07/2025.
//

import Foundation
import Norai

actor MockedEventsMonitor: NoraiEventsMonitorProtocol {
    
    let buffer: any NoraiBufferProtocol
    var isStartMonitoringCalled: Bool = false
    var isStopMonitoringCalled: Bool = false
    var isListentoMonitorStreamCalled: Bool = false
    
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
        Task { await setListenToMonitorStreamCalled() }
        return AsyncStream<Void> { _ in }
    }
    
    private func setListenToMonitorStreamCalled() async {
        isListentoMonitorStreamCalled = true
    }
}
