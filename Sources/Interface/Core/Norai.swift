//
//  Norai.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import Foundation

public final class Norai: @unchecked Sendable {
    private var isConfigured: Bool = false
    private var engine: (any NoraiEngineProtocol)?
    private var sessionManager: (any NoraiSessionManagerProtocol)?
    private var lifecycleObserver: NoraiLifecycleObserver?

    private init() {}
    public static let shared: Norai = Norai()
    private var engineTask: Task<Void, Never>?
    
    private func isValidKeyFormat(_ key: String) -> Bool {
        return key.starts(with: "nk_") &&
        key.count == 67 &&
        key.dropFirst(3).allSatisfy { $0.isHexDigit }
    }
}

public extension Norai {
    func configure(with key: String) {
        guard isValidKeyFormat(key) && !isConfigured else {
            print("[Norai] - Invalid Key format")
            return
        }

        let engine = NoraiEngineFactory.makeEngine(
            with: key,
            identityManager: NoraiIdentityManager(encryptedRepo: KeychainWrapper())
        )

        let sessionManager = NoraiSessionManager(storage: FileSessionStorage())
        self.sessionManager = sessionManager
        self.lifecycleObserver = NoraiLifecycleObserver(sessionManager: sessionManager)

        self.engine = engine
        engineTask?.cancel()
        engineTask = Task {
            await engine.start()
        }

        isConfigured = true
    }
    
    func identifyUser(with id: String) {
        guard isConfigured else {
            print("[Norai] - Norai is not configured.")
            return
        }
        Task {
            await engine?.identify(userID: id)
        }
    }
    
    func upsertUserInfo() {
        guard isConfigured else {
            print("[Norai] - Norai is not configured.")
            return
        }
    }
    
    func trackEvent(name: String, properties: [String: JSONValue]) {
        guard isConfigured else {
            print("[Norai] - Norai is not configured.")
            return
        }
        Task {
            await engine?.trackEvent(name: name, properties: properties)
        }
    }
}
