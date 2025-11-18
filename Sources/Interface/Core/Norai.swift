//
//  Norai.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import Foundation

public final class Norai: @unchecked Sendable {
    private var isConfigured: Bool = false
    private var engine: NoraiEngineProtocol?
    private init() {}
    public static let shared: Norai = Norai()
    private var engineTask: Task<Void, Never>?
    
    private func isValidKeyFormat(_ key: String) -> Bool {
        return key.starts(with: "nk_") &&
        key.count == 67 &&
        key.dropFirst(3).allSatisfy { $0.isHexDigit }
    }
}

extension Norai {
    func configure(with key: String) {
        guard isValidKeyFormat(key) && !isConfigured
        else {
            print("[Norai] - Invalid Key format")
            return
        }
        isConfigured = true
        let engine = NoraiEngineFactory.makeEngine(with: key)
        self.engine = engine
        engineTask?.cancel()
        engineTask = Task {
            await engine.start()
        }
    }
    
    func identifyUser(with id: String) {
        Task {}
    }
    
    func upsertUserInfo() {
        Task {}
    }
    
    func trackEvent(name: String, properties: [String: Encodable]) {
        Task {}
    }
}
