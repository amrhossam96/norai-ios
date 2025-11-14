//
//  NoraiCachingLayer.swift
//  Norai
//
//  Created by Amr on 30/06/2025.
//

import Foundation

enum NoraiCachingLayerError: Error {
    case filePathDoesntExist
    case encodingError
    case decodingError
    case fileWriteError
    case fileSizeExceeded
    case directoryCreationFailed
}

actor NoraiCachingLayer {
    private let fileURL: URL
    private let maxFileSize: Int = 10 * 1024 * 1024
    private let maxEvents: Int = 1000
    
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    init(fileName: String = "norai_cached_events.json") {
        // Use applicationSupportDirectory instead of cachesDirectory
        // This ensures data persists and won't be deleted by iOS
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let noraiDirectory = directory.appendingPathComponent("Norai", isDirectory: true)
        
        // Create Norai directory if it doesn't exist
        try? FileManager.default.createDirectory(at: noraiDirectory, withIntermediateDirectories: true)
        
        self.fileURL = noraiDirectory.appendingPathComponent(fileName)
        
        // Configure encoders for consistent formatting
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        
        print("💾 NoraiCachingLayer initialized at: \(fileURL.path)")
    }
}

extension NoraiCachingLayer: NoraiCachingLayerProtocol {
    /// Efficiently append events to cache file using JSONL format
    func save(_ events: [NoraiEvent]) async throws {
        guard !events.isEmpty else { return }
        
        // Check if we need to rotate the file due to size or count limits
        if await shouldRotateFile() {
            try await rotateFile()
        }
        
        // Append events to file in JSONL format (one JSON object per line)
        var dataToAppend = Data()
        
        for event in events {
            do {
                let eventData = try encoder.encode(event)
                dataToAppend.append(eventData)
                
                // Add newline separator safely
                guard let newlineData = "\n".data(using: .utf8) else {
                    throw NoraiCachingLayerError.encodingError
                }
                dataToAppend.append(newlineData)
            } catch {
                print("❌ Failed to encode event \(event.id): \(error)")
                throw NoraiCachingLayerError.encodingError
            }
        }
        
        // Append to file atomically
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                // Append to existing file
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                defer { fileHandle.closeFile() }
                fileHandle.seekToEndOfFile()
                fileHandle.write(dataToAppend)
            } else {
                // Create new file
                try dataToAppend.write(to: fileURL, options: .atomic)
            }
            
            print("💾 Successfully cached \(events.count) events")
        } catch {
            print("❌ Failed to write events to cache: \(error)")
            throw NoraiCachingLayerError.fileWriteError
        }
    }
    
    /// Read all cached events from JSONL file
    func getAll() async throws -> [NoraiEvent] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return [] // Return empty array instead of throwing error
        }
        
        do {
            let fileContent = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = fileContent.components(separatedBy: .newlines)
            
            var events: [NoraiEvent] = []
            
            for (index, line) in lines.enumerated() {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                guard !trimmedLine.isEmpty else { continue }
                
                guard let lineData = trimmedLine.data(using: .utf8) else {
                    print("⚠️ Failed to convert line \(index) to data")
                    continue
                }
                
                do {
                    let event = try decoder.decode(NoraiEvent.self, from: lineData)
                    events.append(event)
                } catch {
                    print("⚠️ Failed to decode event at line \(index): \(error)")
                    // Continue processing other events instead of failing completely
                }
            }
            
            print("📖 Successfully loaded \(events.count) cached events")
            return events
            
        } catch {
            print("❌ Failed to read cached events: \(error)")
            throw NoraiCachingLayerError.decodingError
        }
    }
    
    /// Clear all cached events
    func clear() async throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return // File doesn't exist, nothing to clear
        }
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("🗑️ Successfully cleared cached events")
        } catch {
            print("❌ Failed to clear cached events: \(error)")
            throw error
        }
    }
    
    // MARK: - File Management
    
    /// Check if file needs rotation due to size or count limits
    private func shouldRotateFile() async -> Bool {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return false
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let fileSize = attributes[.size] as? Int ?? 0
            
            if fileSize > maxFileSize {
                print("📊 Cache file size (\(fileSize) bytes) exceeds limit (\(maxFileSize) bytes)")
                return true
            }
            
            // Check event count by reading lines (faster than decoding all events)
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let lineCount = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
            
            if lineCount > maxEvents {
                print("📊 Cache event count (\(lineCount)) exceeds limit (\(maxEvents))")
                return true
            }
            
            return false
            
        } catch {
            print("⚠️ Failed to check file attributes: \(error)")
            return false
        }
    }
    
    /// Rotate file by keeping only the most recent events
    private func rotateFile() async throws {
        print("🔄 Rotating cache file...")
        
        let allEvents = try await getAll()
        
        // Keep only the most recent events (last 70% of max)
        let keepCount = Int(Double(maxEvents) * 0.7)
        let eventsToKeep = Array(allEvents.suffix(keepCount))
        
        // Clear current file and write reduced set
        try await clear()
        
        if !eventsToKeep.isEmpty {
            try await save(eventsToKeep)
        }
        
        print("🔄 File rotation complete: kept \(eventsToKeep.count) most recent events")
    }
}

// MARK: - Additional Protocol Methods for Enhanced Functionality

extension NoraiCachingLayer {
    /// Get count of cached events without loading all data
    func getEventCount() async -> Int {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return 0
        }
        
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let count = content.components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                .count
            return count
        } catch {
            print("⚠️ Failed to count cached events: \(error)")
            return 0
        }
    }
    
    /// Get cache file size in bytes
    func getCacheSize() async -> Int {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return 0
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            return attributes[.size] as? Int ?? 0
        } catch {
            return 0
        }
    }
}
