//
//  NoraiCachingLayerProtocol.swift
//  Norai
//
//  Created by Amr on 30/06/2025.
//

import Foundation

protocol NoraiCachingLayerProtocol: Sendable {
    func save(_ events: [NoraiEvent]) async throws
    func getAll() async throws -> [NoraiEvent]
    func clear() async throws
    
    // Additional methods for monitoring and management
    func getEventCount() async -> Int
    func getCacheSize() async -> Int
}
