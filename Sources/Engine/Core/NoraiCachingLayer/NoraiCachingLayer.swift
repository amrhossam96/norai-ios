//
//  NoraiCachingLayer.swift
//  Norai
//
//  Created by Amr on 30/06/2025.
//

import Foundation

enum NoraiCachingLayerError: Error {
    case filePathDoesntExist
}

public actor NoraiCachingLayer {
    private let fileURL: URL
    
    public init(fileName: String = "norai_events.json") {
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.fileURL = directory.appending(path: fileName)
    }
}

extension NoraiCachingLayer: NoraiCachingLayerProtocol {
    public func save(_ events: [NoraiEvent]) async throws {
        let existing = try await getAll()
        let allEvents = existing + events
        let data = try JSONEncoder().encode(allEvents)
        try data.write(to: fileURL, options: [.atomic])
    }
    
    public func getAll() async throws -> [NoraiEvent] {
        guard FileManager.default.fileExists(atPath: fileURL.path()) else {
            throw NoraiCachingLayerError.filePathDoesntExist
        }
        
        let data = try Data(contentsOf: fileURL)
        let events = try JSONDecoder().decode([NoraiEvent].self, from: data)
        return events
    }
    
    public func clear() async throws {
        try FileManager.default.removeItem(at: fileURL)
    }
}
