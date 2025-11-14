//
//  NoraiEventsDispatcher.swift
//  Norai
//
//  Created by Amr on 30/06/2025.
//

import Foundation

enum NoraiEventsDispatcherError: Error {
    case emptyPayload
}

actor NoraiEventsDispatcher {
    private let client: any NoraiNetworkClientProtocol
    private let encoder: JSONEncoder = JSONEncoder()
    
    init(client: any NoraiNetworkClientProtocol) {
        self.client = client
    }
}

extension NoraiEventsDispatcher: NoraiEventsDispatcherProtocol {
    func dispatch(events: [NoraiEvent]) async throws {
        guard !events.isEmpty else { throw NoraiEventsDispatcherError.emptyPayload }
        let request: NoraiBatchEventsRequest = NoraiBatchEventsRequest(events: events)
        let endpoint = NoraiDispatchEventEndPoint.sendEventsInBatch(request)
        let response: NoraiBatchEventsResponse = try await client.execute(endpoint)
        print("✅ Successfully dispatched \(events.count) events - Server response: \(response.message)")
    }
}
