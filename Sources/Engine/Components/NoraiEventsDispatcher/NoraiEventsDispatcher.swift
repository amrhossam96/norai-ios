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
    
    init(client: any NoraiNetworkClientProtocol) {
        self.client = client
    }
}

extension NoraiEventsDispatcher: NoraiEventsDispatcherProtocol {
    func syncIdentity(payload: NoraiUserIdentity) async throws -> NoraiIdentificationSyncingResponse {
        let endPoint = NoraiIdentitySyncingEndPoint.identify(payload)
        let response: NoraiIdentificationSyncingResponse = try await client.execute(endPoint)
        return response
    }
    
    @discardableResult
    func dispatch(eventsBatch: NoraiEventBatch) async throws -> NoraiBatchEventsResponse {
        guard !eventsBatch.events.isEmpty else { throw NoraiEventsDispatcherError.emptyPayload }
        let endPoint = NoraiDispatchEventEndPoint.sendEventsInBatch(eventsBatch)
        return try await client.execute(endPoint) as NoraiBatchEventsResponse
    }
}
