//
//  NoraiEventsMonitor.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation

protocol NoraiEventsMonitorProtocol: Sendable {
    var buffer: NoraiBufferProtocol { get }
    func startMonitoring() async throws
    func stopMonitoring() async throws
    func listenToMonitorStream() async -> AsyncStream<Void>
}
