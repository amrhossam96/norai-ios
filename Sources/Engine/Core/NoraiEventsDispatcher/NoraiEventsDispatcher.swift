//
//  NoraiEventsDispatcher.swift
//  Norai
//
//  Created by Amr on 30/06/2025.
//

import Foundation

// No specific dispatcher errors needed - will throw network client errors directly

actor NoraiEventsDispatcher {
    let client: any NoraiNetworkClientProtocol
    
    init(
        client: any NoraiNetworkClientProtocol
    ) {
        self.client = client
    }
}

extension NoraiEventsDispatcher: NoraiEventsDispatcherProtocol {
    func dispatch(events: [NoraiEvent]) async throws {
        guard !events.isEmpty else { return }
        
        // 🔍 Debug: Print encoded events
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(events)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "Failed to convert to string"
            print("📡 DISPATCHING \(events.count) EVENTS:")
            print(String(repeating: "=", count: 50))
            print(jsonString)
            print(String(repeating: "=", count: 50))
        } catch {
            print("❌ Failed to encode events for debugging: \(error)")
        }
        
        let request: NoraiBatchEventsRequest = NoraiBatchEventsRequest(events: events)
        let endpoint = NoraiDispatchEventEndPoint.sendEventsInBatch(request)
        
        let response: NoraiBatchEventsResponse = try await client.execute(endpoint)
        print("✅ Successfully dispatched \(events.count) events - Server response: \(response.message)")
    }
}
