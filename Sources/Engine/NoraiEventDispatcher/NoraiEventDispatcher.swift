//
//  NoraiEventDispatcher.swift
//  Norai
//
//  Created by Amr on 04/06/2025.
//

import Foundation

class NoraiEventDispatcher {
    private let apiClient: any NoraiNetworkClientProtocol

    init(apiClient: any NoraiNetworkClientProtocol) {
        self.apiClient = apiClient
    }
}

extension NoraiEventDispatcher: NoraiEventDispatcherProtocol {
    func enqueue(events: [NoraiEvent]) async {
        do {
            let _: TrackEventsResponse = try await apiClient.execute(NoraiAnalyticsEndPoint.track(events: events))
        } catch {
            
        }
    }
}
