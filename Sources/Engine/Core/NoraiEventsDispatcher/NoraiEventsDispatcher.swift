//
//  NoraiEventsDispatcher.swift
//  Norai
//
//  Created by Amr on 30/06/2025.
//

import Foundation

struct NoraiEventsDispatcher {
    let client: any NoraiNetworkClientProtocol
    let cache: any NoraiCachingLayerProtocol
    var networkMonitor: any NoraiNetworkMonitorProtocol
}

extension NoraiEventsDispatcher: NoraiEventsDispatcherProtocol {
    func dispatch(events: [NoraiEvent]) async {
        guard await networkMonitor.isNetworkAvailable() else {
            // TODO: Cache events
            return
        }
        // TODO: - Send Over Network
    }
}
