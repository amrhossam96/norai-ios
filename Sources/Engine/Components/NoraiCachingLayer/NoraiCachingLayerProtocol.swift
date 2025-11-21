//
//  NoraiCachingLayerProtocol.swift
//  Norai
//
//  Created by Amr on 30/06/2025.
//

import Foundation

protocol NoraiCachingLayerProtocol {
    func save(_ batch: NoraiEventBatch) async throws
    func loadAll() async throws -> [NoraiEventBatch]
    func clearAll() async throws

    func currentFileBatchCount() async -> Int
    func currentFileSize() async -> Int
}
