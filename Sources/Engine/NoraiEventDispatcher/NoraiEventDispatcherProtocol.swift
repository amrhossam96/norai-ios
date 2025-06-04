//
//  NoraiEventDispatcherProtocol.swift
//  Norai
//
//  Created by Amr on 04/06/2025.
//

import Foundation

public protocol NoraiEventDispatcherProtocol {
    func enqueue(events: [NoraiEvent]) async
}
