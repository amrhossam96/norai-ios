//
//  NoraiSessionStorage.swift
//  Norai
//
//  Created by Amr Hossam on 20/11/2025.
//

import Foundation

public final class FileSessionStorage: NoraiSessionStorageProtocol {

    private struct SessionData: Codable {
        var sessionID: String
        var sessionStart: Date
        var lastActivity: Date
    }

    private let fileURL: URL
    private var cachedData: SessionData?

    public init(fileName: String = "norai_session.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = documents.appendingPathComponent(fileName)
        self.cachedData = try? loadFile()
    }

    private func loadFile() throws -> SessionData {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(SessionData.self, from: data)
    }

    public func loadSessionID() -> String? {
        cachedData?.sessionID
    }

    public func loadSessionStart() -> Date? {
        cachedData?.sessionStart
    }

    public func loadLastActivity() -> Date? {
        cachedData?.lastActivity
    }

    public func saveSessionID(_ id: String) async {
        updateCached { $0.sessionID = id }
    }

    public func saveSessionStart(_ date: Date) async {
        updateCached { $0.sessionStart = date }
    }

    public func saveLastActivity(_ date: Date) async {
        updateCached { $0.lastActivity = date }
    }

    public func clear() async {
        cachedData = nil
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func updateCached(_ update: (inout SessionData) -> Void) {
        var data = cachedData ?? SessionData(sessionID: UUID().uuidString,
                                             sessionStart: Date(),
                                             lastActivity: Date())
        update(&data)
        cachedData = data
        Task { @MainActor in
            do {
                let encoded = try JSONEncoder().encode(data)
                try encoded.write(to: fileURL, options: [.atomic])
            } catch {
                print("NoraiSessionStorage error saving file:", error)
            }
        }
    }
}
