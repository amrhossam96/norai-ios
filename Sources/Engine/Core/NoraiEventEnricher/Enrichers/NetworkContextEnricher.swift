//
//  NetworkContextEnricher.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import Foundation
import Network

public struct NetworkContextEnricher: NoraiEventEnricherProtocol {
    private let networkMonitor: NoraiNetworkMonitorProtocol
    
    public init(networkMonitor: NoraiNetworkMonitorProtocol) {
        self.networkMonitor = networkMonitor
    }
    
    public func enrich(event: NoraiEvent, with state: NoraiEngineState) async -> NoraiEvent {
        var enrichedEvent = event
        
        // Add network type information
        let isConnected = await networkMonitor.isNetworkAvailable()
        enrichedEvent.metadata.networkType = isConnected ? "wifi" : "none"
        
        // You can enhance this to detect cellular vs wifi vs ethernet
        // This would require additional network path monitoring
        
        return enrichedEvent
    }
} 