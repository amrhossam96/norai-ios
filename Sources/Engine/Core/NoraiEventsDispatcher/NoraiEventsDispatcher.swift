//
//  NoraiEventsDispatcher.swift
//  Norai
//
//  Created by Amr on 30/06/2025.
//

import Foundation

struct NoraiEventsDispatcher {
    let client: NoraiNetworkClientProtocol
    let cache: NoraiCachingLayerProtocol
}

extension NoraiEventsDispatcher: NoraiEventsDispatcherProtocol {
    func dispatch(events: [NoraiEvent]) async {
        
    }
}
