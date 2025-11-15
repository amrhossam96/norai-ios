//
//  NoraiCachingLayer.swift
//  Norai
//
//  Created by Amr on 30/06/2025.
//

import Foundation

actor NoraiCachingLayer {
    private let fileURL: URL
    private let maxFileSize: Int = 10 * 1024 * 1024
    private let maxEvents: Int = 1000
    
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    public init(filename: String = "norai_cached_events.json") {
        let directory = FileManager.default
            .urls(for: .userDirectory, in: .userDomainMask)[0]
            .appending(path: "Norai", directoryHint: .isDirectory)
        do {
            try FileManager.default.createDirectory(at: directory,
                                                    withIntermediateDirectories: true)
        } catch {
            fatalError()
        }
        self.fileURL = directory.appendingPathComponent(filename)
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    private func rotateFile() async throws {
        let allEvents = try await getAll()
        let keepCount = Int(Double(maxEvents) * 0.7)
        let eventsTokeep = Array(allEvents.suffix(keepCount))
        try await clear()
        if !eventsTokeep.isEmpty {
            try await save(eventsTokeep)
        }
    }
    
    private func shouldRotateFile() async -> Bool {
        guard FileManager.default.fileExists(atPath: fileURL.path()) else { return false }
        let attrs: [FileAttributeKey: Any]
        let content: String
        do {
            attrs = try FileManager.default.attributesOfItem(atPath: fileURL.path())
            content = try String(contentsOf: fileURL)
        } catch {
            return false
        }
        if let fileSize = attrs[.size] as? Int,
           fileSize > maxFileSize {
            return true
        }
        let lineCount = content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
        return lineCount > maxEvents
    }
}

extension NoraiCachingLayer: NoraiCachingLayerProtocol {
    func save(_ events: [NoraiEvent]) async throws {
        guard !events.isEmpty else { return }
        if await shouldRotateFile() {
            try await rotateFile()
        }
        var dataToAppend = Data()
        for event in events {
            let jsonData: Data = try encoder.encode(event)
            dataToAppend.append(jsonData)
            
            guard let newlineData = "\n".data(using: .utf8) else {
                throw NoraiCachingLayerError.encodingError
            }
            dataToAppend.append(newlineData)
        }
        
        if FileManager.default.fileExists(atPath: fileURL.path()) {
            let handle = try FileHandle(forWritingTo: fileURL)
            try handle.seekToEnd()
            try handle.write(contentsOf: dataToAppend)
        } else {
            try dataToAppend.write(to: fileURL, options: .atomic)
        }
    }
    
    func getAll() async throws -> [NoraiEvent] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        let fileContent = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = fileContent.components(separatedBy: .newlines)

        var events: [NoraiEvent] = []
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty else { continue }
            
            if let data = trimmedLine.data(using: .utf8) {
                do {
                    let event = try decoder.decode(NoraiEvent.self, from: data)
                    events.append(event)
                } catch {
                    print("⚠️ Failed to decode event at line \(index): \(error)")
                    continue
                }
            }
        }
        
        return events
    }
    
    func clear() async throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try FileManager.default.removeItem(at: fileURL)
    }
    
    func getEventCount() async -> Int {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return 0 }
        
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let count = content
                .components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .count
            return count
        } catch {
            print("⚠️ Failed to count cached events: \(error)")
            return 0
        }
    }

    
    func getCacheSize() async -> Int {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return 0 }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            return attributes[.size] as? Int ?? 0
        } catch {
            print("⚠️ Failed to get cache file size: \(error)")
            return 0
        }
    }
}
