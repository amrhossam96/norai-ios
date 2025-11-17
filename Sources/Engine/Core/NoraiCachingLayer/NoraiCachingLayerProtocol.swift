//
//  NoraiCachingLayerProtocol.swift
//  Norai
//
//  Created by Amr on 30/06/2025.
//

import Foundation

protocol NoraiCachingLayerProtocol {
    func save(_ events: [NoraiEvent]) async throws
    func loadAll() async throws -> [NoraiEvent]
    func clearAll() async throws
    
    func currentFileEventCount() async -> Int
    func currentFileSize() async -> Int
}
