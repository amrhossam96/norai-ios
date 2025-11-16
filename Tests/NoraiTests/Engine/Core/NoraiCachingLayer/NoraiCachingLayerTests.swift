//
//  NoraiCachingLayerTests.swift
//  Norai
//
//  Created by Amr Hossam on 16/11/2025.
//

import Testing
import Foundation
import Norai

@Suite("NoraiCachingLayer Tests")
struct NoraiCachingLayerTests {

    @Test("Save and load events")
    func saveAndLoad() async throws {
        let tempDir = makeTempDirectory()
        defer { cleanupDirectory(tempDir) }
        
        let cache = try NoraiCachingLayer(
            folderName: "TestCache",
            baseDirectory: tempDir
        )
        
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        
        let events = [
            makeTestEvent(id: id1),
            makeTestEvent(id: id2),
            makeTestEvent(id: id3)
        ]
        
        try await cache.save(events)
        let loaded = try await cache.loadAll()
        
        #expect(loaded.count == 3)
        #expect(loaded[0].id == id1)
        #expect(loaded[1].id == id2)
        #expect(loaded[2].id == id3)
    }
    
    @Test("Save empty array does nothing")
    func saveEmpty() async throws {
        let tempDir = makeTempDirectory()
        defer { cleanupDirectory(tempDir) }
        
        let cache = try NoraiCachingLayer(
            folderName: "TestCache",
            baseDirectory: tempDir
        )
        
        try await cache.save([])
        let loaded = try await cache.loadAll()
        
        #expect(loaded.isEmpty)
    }
    
    @Test("Load from empty cache returns empty array")
    func loadEmpty() async throws {
        let tempDir = makeTempDirectory()
        defer { cleanupDirectory(tempDir) }
        
        let cache = try NoraiCachingLayer(
            folderName: "TestCache",
            baseDirectory: tempDir
        )
        
        let loaded = try await cache.loadAll()
        #expect(loaded.isEmpty)
    }
    
    @Test("Multiple save operations append events")
    func multipleSaves() async throws {
        let tempDir = makeTempDirectory()
        defer { cleanupDirectory(tempDir) }
        
        let cache = try NoraiCachingLayer(
            folderName: "TestCache",
            baseDirectory: tempDir
        )
        
        try await cache.save([makeTestEvent(id: UUID())])
        try await cache.save([makeTestEvent(id: UUID())])
        try await cache.save([makeTestEvent(id: UUID())])
        
        let loaded = try await cache.loadAll()
        #expect(loaded.count == 3)
    }
    
    // MARK: - File Rotation
    
    @Test("Rotation occurs when max events reached")
    func rotationByEventCount() async throws {
        let tempDir = makeTempDirectory()
        defer { cleanupDirectory(tempDir) }
        
        let cache = try NoraiCachingLayer(
            folderName: "TestCache",
            baseDirectory: tempDir,
            maxEvents: 2  // Small limit for testing
        )
        
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        let id4 = UUID()
        
        // Save first batch (reaches limit)
        try await cache.save([
            makeTestEvent(id: id1),
            makeTestEvent(id: id2)
        ])
        
        let countBefore = await cache.currentFileEventCount()
        #expect(countBefore == 2)
        
        // Save second batch (triggers rotation)
        try await cache.save([
            makeTestEvent(id: id3),
            makeTestEvent(id: id4)
        ])
        
        // All events should be preserved across files
        let loaded = try await cache.loadAll()
        #expect(loaded.count == 4)
        
        let ids = Set(loaded.map { $0.id })
        #expect(ids == Set([id1, id2, id3, id4]))
    }
    
    @Test("Rotation occurs when max size reached")
    func rotationByFileSize() async throws {
        let tempDir = makeTempDirectory()
        defer { cleanupDirectory(tempDir) }
        
        let cache = try NoraiCachingLayer(
            folderName: "TestCache",
            baseDirectory: tempDir,
            maxSize: 200  // Small limit
        )
        
        // Create event with large properties
        let largeEvent = NoraiEvent(
            id: UUID(),
            event: "test",
            timestamp: Date(),
            properties: ["data": String(repeating: "x", count: 100)]
        )
        
        try await cache.save([largeEvent])
        
        let sizeBefore = await cache.currentFileSize()
        #expect(sizeBefore > 0)
        
        // Save another large event (should trigger rotation)
        let largeEvent2 = NoraiEvent(
            id: UUID(),
            event: "test",
            timestamp: Date(),
            properties: ["data": String(repeating: "y", count: 100)]
        )
        
        try await cache.save([largeEvent2])
        
        let loaded = try await cache.loadAll()
        #expect(loaded.count == 2)
    }
    
    // MARK: - Clear Operations
    
    @Test("Clear all removes all events")
    func clearAll() async throws {
        let tempDir = makeTempDirectory()
        defer { cleanupDirectory(tempDir) }
        
        let cache = try NoraiCachingLayer(
            folderName: "TestCache",
            baseDirectory: tempDir
        )
        
        // Save events
        try await cache.save([
            makeTestEvent(id: UUID()),
            makeTestEvent(id: UUID())
        ])
        
        var loaded = try await cache.loadAll()
        #expect(loaded.count == 2)
        
        // Clear
        try await cache.clearAll()
        
        // Verify cleared
        loaded = try await cache.loadAll()
        #expect(loaded.isEmpty)
    }
    
    // MARK: - File Metrics
    
    @Test("Current file event count is accurate")
    func eventCount() async throws {
        let tempDir = makeTempDirectory()
        defer { cleanupDirectory(tempDir) }
        
        let cache = try NoraiCachingLayer(
            folderName: "TestCache",
            baseDirectory: tempDir
        )
        
        var count = await cache.currentFileEventCount()
        #expect(count == 0)
        
        try await cache.save([
            makeTestEvent(id: UUID()),
            makeTestEvent(id: UUID()),
            makeTestEvent(id: UUID())
        ])
        
        count = await cache.currentFileEventCount()
        #expect(count == 3)
    }
    
    @Test("Current file size is accurate")
    func fileSize() async throws {
        let tempDir = makeTempDirectory()
        defer { cleanupDirectory(tempDir) }
        
        let cache = try NoraiCachingLayer(
            folderName: "TestCache",
            baseDirectory: tempDir
        )
        
        var size = await cache.currentFileSize()
        #expect(size == 0)
        
        try await cache.save([makeTestEvent(id: UUID())])
        
        size = await cache.currentFileSize()
        #expect(size > 0)
    }
    
    // MARK: - Data Integrity
    
    @Test("Event properties are preserved")
    func dataIntegrity() async throws {
        let tempDir = makeTempDirectory()
        defer { cleanupDirectory(tempDir) }
        
        let cache = try NoraiCachingLayer(
            folderName: "TestCache",
            baseDirectory: tempDir
        )
        
        let properties: [String: String] = [
            "user_id": "user_123",
            "action": "click",
            "count": "42"
        ]
        
        let event = NoraiEvent(
            id: UUID(),
            event: "user_action",
            timestamp: Date(),
            properties: properties
        )
        
        try await cache.save([event])
        let loaded = try await cache.loadAll()
        
        #expect(loaded.count == 1)
        #expect(loaded[0].id == event.id)
        #expect(loaded[0].event == "user_action")
        #expect(loaded[0].properties == properties)
    }
    
    @Test("ISO8601 dates are preserved")
    func dateEncoding() async throws {
        let tempDir = makeTempDirectory()
        defer { cleanupDirectory(tempDir) }
        
        let cache = try NoraiCachingLayer(
            folderName: "TestCache",
            baseDirectory: tempDir
        )
        
        let originalDate = Date()
        let event = NoraiEvent(
            id: UUID(),
            event: "test",
            timestamp: originalDate,
            properties: [:]
        )
        
        try await cache.save([event])
        let loaded = try await cache.loadAll()
        
        #expect(loaded.count == 1)
        // Allow small time difference due to encoding/decoding precision
        let timeDifference = abs(loaded[0].timestamp?.timeIntervalSince(originalDate) ?? .zero)
        #expect(timeDifference < 1.0)
    }
    
    // MARK: - Concurrent Access
    
    @Test("Concurrent saves are handled safely")
    func concurrentAccess() async throws {
        let tempDir = makeTempDirectory()
        defer { cleanupDirectory(tempDir) }
        
        let cache = try NoraiCachingLayer(
            folderName: "TestCache",
            baseDirectory: tempDir
        )
        
        // Perform concurrent saves
        await withTaskGroup(of: Void.self) { group in
            for _ in 1...10 {
                group.addTask {
                    let event = makeTestEvent(id: UUID())
                    try? await cache.save([event])
                }
            }
        }
        
        let loaded = try await cache.loadAll()
        #expect(loaded.count == 10)
        
        let uniqueIds = Set(loaded.map { $0.id })
        #expect(uniqueIds.count == 10)
    }
    
    // MARK: - Directory Isolation
    
    @Test("Directory is created correctly")
    func directoryCreation() throws {
        let tempDir = makeTempDirectory()
        defer { cleanupDirectory(tempDir) }
        
        let cache = try NoraiCachingLayer(
            folderName: "TestCache",
            baseDirectory: tempDir
        )
        
        let expectedPath = tempDir
            .appendingPathComponent("TestCache")
            .path
        
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: expectedPath,
            isDirectory: &isDirectory
        )
        
        #expect(exists)
        #expect(isDirectory.boolValue)
        // Prevent unused warning
        _ = cache
    }
    
    @Test("Each test uses isolated directory")
    func isolation() throws {
        let dir1 = makeTempDirectory()
        let dir2 = makeTempDirectory()
        defer {
            cleanupDirectory(dir1)
            cleanupDirectory(dir2)
        }
        
        #expect(dir1.path != dir2.path)
        #expect(dir1.path.contains("NoraiTests"))
        #expect(dir2.path.contains("NoraiTests"))
    }
}

// MARK: - Test Helpers
extension NoraiCachingLayerTests {
    func makeTempDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("NoraiTests")
            .appendingPathComponent(UUID().uuidString)
    }
    
    func cleanupDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    func makeTestEvent(id: UUID) -> NoraiEvent {
        NoraiEvent(
            id: id,
            event: "test",
            timestamp: Date(),
            properties: [:]
        )
    }
}
