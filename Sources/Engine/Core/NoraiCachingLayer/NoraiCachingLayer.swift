//
//  NoraiCachingLayer.swift
//  Norai
//
//  Created by Amr on 30/06/2025.
//

import Foundation

public actor NoraiCachingLayer {
    
    // MARK: - File Config
    
    private let directory: URL
    private let currentFile: URL
    private let previousFile: URL
    
    private let maxEvents: Int
    private let maxSize: Int
    
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    // MARK: - Init
    
    public init(
        folderName: String = "NoraiCache",
        baseDirectory: URL? = nil,
        maxEvents: Int = 10_000,
        maxSize: Int = 5 * 1024 * 1024
    ) throws {
        // Configure directories
        let base = baseDirectory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.directory = base.appendingPathComponent(folderName, isDirectory: true)
        self.currentFile = directory.appendingPathComponent("events_current.jsonl")
        self.previousFile = directory.appendingPathComponent("events_previous.jsonl")
        
        // Configure limits
        self.maxEvents = maxEvents
        self.maxSize = maxSize
        
        // Configure coders
        self.encoder = Self.makeEncoder()
        self.decoder = Self.makeDecoder()
        
        // Create directory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    
    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
    
    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
    
    // MARK: - Private Helpers
    
    private func needsRotation() async -> Bool {
        let count = await currentFileEventCount()
        if count >= maxEvents { return true }
        let size = await currentFileSize()
        if size >= maxSize { return true }
        return false
    }
    
    private func rotate() async throws {
        if FileManager.default.fileExists(atPath: previousFile.path) {
            try FileManager.default.removeItem(at: previousFile)
        }
        
        if FileManager.default.fileExists(atPath: currentFile.path) {
            try FileManager.default.moveItem(at: currentFile, to: previousFile)
        }
        
        FileManager.default.createFile(atPath: currentFile.path, contents: nil)
    }
    
    private func getHandleForAppending() throws -> FileHandle {
        if !FileManager.default.fileExists(atPath: currentFile.path) {
            FileManager.default.createFile(atPath: currentFile.path, contents: nil)
        }
        let handle = try FileHandle(forWritingTo: currentFile)
        try handle.seekToEnd()
        return handle
    }
    
    private func readFile(_ url: URL) async throws -> [NoraiEvent] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        
        let content = try String(contentsOf: url)
        
        var events: [NoraiEvent] = []
        
        for line in content.split(separator: "\n") {
            if let data = line.data(using: .utf8) {
                do {
                    let event = try decoder.decode(NoraiEvent.self, from: data)
                    events.append(event)
                } catch {
                    throw NoraiCachingLayerError.decodingError
                }
            }
        }
        return events
    }
}

// MARK: - NoraiCachingLayerProtocol

extension NoraiCachingLayer: NoraiCachingLayerProtocol {
    
    func save(_ events: [NoraiEvent]) async throws {
        guard !events.isEmpty else { return }
        
        if await needsRotation() {
            try await rotate()
        }
        
        let handle = try getHandleForAppending()
        defer { try? handle.close() }
        for event in events {
            let data = try encoder.encode(event)
            guard let newline = "\n".data(using: .utf8) else { continue }
            try handle.write(contentsOf: data + newline)
        }
    }
    
    func loadAll() async throws -> [NoraiEvent] {
        let files = [previousFile, currentFile]
        var all: [NoraiEvent] = []
        
        for file in files {
            let events = try await readFile(file)
            all.append(contentsOf: events)
        }
        
        return all
    }
    
    public func clearAll() async throws {
        try? FileManager.default.removeItem(at: currentFile)
        try? FileManager.default.removeItem(at: previousFile)
    }
    
    public func currentFileEventCount() async -> Int {
        guard let content = try? String(contentsOf: currentFile) else { return 0 }
        return content.split(separator: "\n").count
    }
    
    public func currentFileSize() async -> Int {
        guard let attr = try? FileManager.default.attributesOfItem(atPath: currentFile.path) else { return 0 }
        return (attr[.size] as? Int) ?? 0
    }
}
