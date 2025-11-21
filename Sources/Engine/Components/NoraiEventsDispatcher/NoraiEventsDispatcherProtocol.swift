//
//  NoraiEventsDispatcherProtocol.swift
//  Norai
//
//  Created by Amr on 30/06/2025.
//

import Foundation

protocol NoraiEventsDispatcherProtocol: Sendable {
    func dispatch(eventsBatch: NoraiEventBatch) async throws -> NoraiBatchEventsResponse
    func syncIdentity(payload: NoraiUserIdentity) async throws -> NoraiIdentificationSyncingResponse
}
