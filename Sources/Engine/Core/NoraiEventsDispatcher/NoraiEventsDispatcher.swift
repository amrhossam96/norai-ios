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
    
    init(client: any NoraiNetworkClientProtocol, cache: any NoraiCachingLayerProtocol, networkMonitor: any NoraiNetworkMonitorProtocol) {
        self.client = client
        self.cache = cache
        self.networkMonitor = networkMonitor
    }
}

extension NoraiEventsDispatcher: NoraiEventsDispatcherProtocol {
    func dispatch(events: [NoraiEvent]) async throws -> Bool {
        guard await networkMonitor.isNetworkAvailable() else {
            // TODO: Cache events
            throw NoraiEventsDispatcherErrors.networkUnavailable
        }
        let request: NoraiBatchEventsRequest = NoraiBatchEventsRequest(events: events)
        let endpoint = NoraiDispatchEventEndPoint.sendEventsInBatch(request)
        let response: NoraiBatchEventsResponse = try await client.execute(endpoint)
        return response.status == true
    }
}
