//
//  NoraiCachingLayerProtocol.swift
//  Norai
//
//  Created by Amr on 30/06/2025.
//

import Foundation

public protocol NoraiCachingLayerProtocol {
    func save(_ events: [NoraiEvent]) async
    func getAll() async -> [NoraiEvent]
    func clear() async
}
