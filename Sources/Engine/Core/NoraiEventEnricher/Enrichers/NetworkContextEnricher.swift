//
//  NetworkContextEnricher.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import Foundation
import Network

struct NetworkContextEnricher: NoraiEventEnricherProtocol {
    private let networkMonitor: NoraiNetworkMonitorProtocol
    
    init(networkMonitor: NoraiNetworkMonitorProtocol) {
        self.networkMonitor = networkMonitor
    }
    
    func enrich(event: NoraiEvent) async -> NoraiEvent {
        var enrichedEvent = event
        let isConnected = await networkMonitor.isNetworkAvailable()

        return enrichedEvent
    }
} 
