//
//  NoraiIdentityManager.swift
//  Norai
//
//  Created by Amr Hossam on 18/11/2025.
//

import Foundation

actor NoraiIdentityManager {
    private let encryptedRepo: EncryptedRepositoryProtocol
    private let anonymousIDKey = "norai_anonymous_id"
    private var userID: String?
    private var anonymousID: UUID
    
    init(encryptedRepo: EncryptedRepositoryProtocol) {
        self.encryptedRepo = encryptedRepo
        if let data = encryptedRepo.get(anonymousIDKey),
           let restored = try? JSONDecoder().decode(UUID.self, from: data) {
            self.anonymousID = restored
        } else {
            self.anonymousID = UUID()
            Task { await persistAnonymousID() }
        }
    }
    
    private func persistAnonymousID() {
        if let data = try? JSONEncoder().encode(anonymousID) {
            encryptedRepo.set(data, for: anonymousIDKey)
        }
    }
}

// MARK: - NoraiIdentityManagerProtocol

extension NoraiIdentityManager: NoraiIdentityManagerProtocol {
    func identify(userID: String) async {
        
    }
    
    func logout() async {
        anonymousID = UUID()
        persistAnonymousID()
    }
    
    func currentIdentity() async -> (userID: String?, anonymousID: UUID) {
        return (userID, anonymousID)
    }
}

