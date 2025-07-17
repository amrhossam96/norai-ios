//
//  NoraiEventsDispatcher.swift
//  Norai
//
//  Created by Amr on 30/06/2025.
//

import Foundation

enum NoraiEventsDispatcherErrors: Error {
    case networkUnavailable
}

actor NoraiEventsDispatcher {
    let client: any NoraiNetworkClientProtocol
    let cache: any NoraiCachingLayerProtocol
    var networkMonitor: any NoraiNetworkMonitorProtocol
    
    init(
        client: any NoraiNetworkClientProtocol,
        cache: any NoraiCachingLayerProtocol,
        networkMonitor: any NoraiNetworkMonitorProtocol
    ) {
        self.client = client
        self.cache = cache
        self.networkMonitor = networkMonitor
    }
}

extension NoraiEventsDispatcher: NoraiEventsDispatcherProtocol {
    func dispatch(events: [NoraiEvent]) async throws {
        let networkAvailable = await networkMonitor.isNetworkAvailable()
        print("🌐 Network status: \(networkAvailable ? "Available" : "Unavailable")")
        
        guard networkAvailable else {
            print("❌ Network unavailable - cannot dispatch events")
            // TODO: Cache events
            throw NoraiEventsDispatcherErrors.networkUnavailable
        }
        
        // 🔍 Debug: Print encoded events
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(events)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "Failed to convert to string"
            print("📡 DISPATCHING EVENTS:")
            print(String(repeating: "=", count: 50))
            print(jsonString)
            print(String(repeating: "=", count: 50))
        } catch {
            print("❌ Failed to encode events for debugging: \(error)")
        }
        
        let request: NoraiBatchEventsRequest = NoraiBatchEventsRequest(events: events)
        let endpoint = NoraiDispatchEventEndPoint.sendEventsInBatch(request)
        let _: NoraiBatchEventsResponse = try await client.execute(endpoint)
    }
}
