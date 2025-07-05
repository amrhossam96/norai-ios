//
//  NoraiNetworkMonitor.swift
//  Norai
//
//  Created by Amr on 02/07/2025.
//

import Foundation
import Network

public actor NoraiNetworkMonitor {
    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private var isConnected: Bool
    
    public init(monitor: NWPathMonitor = NWPathMonitor(),
                queue: DispatchQueue = DispatchQueue(label: "com.norai.backgroundQueue", qos: .background),
                isConnected: Bool = false) {
        self.monitor = monitor
        self.queue = queue
        self.isConnected = isConnected
    }
    
    private func handlePathUpdate(_ path: NWPath) {
        self.isConnected = path.status == .satisfied
    }
}

extension NoraiNetworkMonitor: NoraiNetworkMonitorProtocol {
    public func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            Task { [weak self] in
                guard let self else { return }
                await handlePathUpdate(path)
            }
        }
    }
    
    public func isNetworkAvailable() -> Bool {
        return isConnected
    }
}
