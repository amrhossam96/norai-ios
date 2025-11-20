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
    
    func dispatch(events: [NoraiEvent]) async throws {
        guard !events.isEmpty else { throw NoraiEventsDispatcherError.emptyPayload }
        _ = try await withThrowingTaskGroup(of: NoraiEventDispatchedResponse.self) { group in
            for event in events {
                group.addTask { [client] in
                    let endpoint = NoraiDispatchEventEndPoint.sendEventIndividually(event)
                    return try await client.execute(endpoint) as NoraiEventDispatchedResponse
                }
            }

            var responses: [NoraiEventDispatchedResponse] = []
            for try await result in group {
                responses.append(result)
            }

            return responses
        }
    }
}
