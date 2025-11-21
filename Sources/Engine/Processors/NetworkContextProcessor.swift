//
//  NetworkContextProcessor.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import Foundation

struct NetworkContextProcessor: NoraiEventProcessorProtocol {
    private let networkMonitor: NoraiNetworkMonitorProtocol

    init(networkMonitor: NoraiNetworkMonitorProtocol) {
        self.networkMonitor = networkMonitor
    }
    
    func process(batch: NoraiEventBatch) async -> NoraiEventBatch {
        var processedBatch = batch
        let isConnected = await networkMonitor.isNetworkAvailable()
        processedBatch.metaData["is_connected"] = .bool(isConnected)
        if let type = await networkMonitor.connectionType() {
            processedBatch.metaData["connection_type"] = .string(type)
        }
        return processedBatch
    }
}


