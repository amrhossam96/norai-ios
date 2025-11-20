//
//  NetworkContextEnricher.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import Foundation

struct NetworkContextEnricher: NoraiEventEnricherProtocol {
    private let networkMonitor: NoraiNetworkMonitorProtocol

    init(networkMonitor: NoraiNetworkMonitorProtocol) {
        self.networkMonitor = networkMonitor
    }

    func enrich(event: NoraiEvent) async -> NoraiEvent {
        var enrichedEvent = event
        let isConnected = await networkMonitor.isNetworkAvailable()
        enrichedEvent.metaData["is_connected"] = .bool(isConnected)

        if let type = await networkMonitor.connectionType() {
            enrichedEvent.metaData["connection_type"] = .string(type)
        }
        return enrichedEvent
    }
}

