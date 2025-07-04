//
//  NoraiEventsDispatcherProtocol.swift
//  Norai
//
//  Created by Amr on 30/06/2025.
//

import Foundation

public protocol NoraiEventsDispatcherProtocol: Sendable {
    func dispatch(events: [NoraiEvent]) async throws
}
