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
        let wasConnected = self.isConnected
        self.isConnected = path.status == .satisfied
        
        if wasConnected != self.isConnected {
            print("📶 Network status changed: \(self.isConnected ? "Connected" : "Disconnected") (\(path.status))")
        }
    }
}

extension NoraiNetworkMonitor: NoraiNetworkMonitorProtocol {
    public func startMonitoring() async {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            Task { [weak self] in
                guard let self else { return }
                await handlePathUpdate(path)
            }
        }
        monitor.start(queue: queue)
        handlePathUpdate(monitor.currentPath)
    }
    
    public func isNetworkAvailable() async -> Bool {
        return isConnected
    }
    
    public func connectionType() async -> String? {
        switch monitor.currentPath.availableInterfaces.first?.type {
            case .wifi: return "wifi"
            case .cellular: return "cellular"
            case .wiredEthernet: return "ethernet"
            default: return nil
            }
    }
}
