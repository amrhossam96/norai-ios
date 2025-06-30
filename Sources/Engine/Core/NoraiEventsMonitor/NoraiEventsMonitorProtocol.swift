//
//  NoraiEventsMonitor.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation

public protocol NoraiEventsMonitorProtocol {
    var buffer: NoraiBufferProtocol { get }
    func startMonitoring(with delegate: NoraiEventsMonitorDelegateProtocol) async throws
}
