//
//  NoraiIdentityManager.swift
//  Norai
//
//  Created by Amr Hossam on 17/11/2025.
//

import Foundation

public final class NoraiIdentityManager {
    private let keychain: KeychainWrapperProtocol
    private let anonymousKey: String = "com.norai.sdk.anonymous_id"
    
    private var anonymousID: UUID
    private var userID: String?
    
    
    public init(keychain: KeychainWrapperProtocol) {
        self.keychain = keychain
        if let data = keychain.get(anonymousKey),
           let str = String(data: data, encoding: .utf8),
           let uuid = UUID(uuidString: str) {
            self.anonymousID = uuid
        } else {
            let new = UUID()
            self.anonymousID = new
            keychain.set(Data(new.uuidString.utf8), for: anonymousKey)
        }
    }
}

extension NoraiIdentityManager: NoraiIdentityManagerProtocol {
    public func getAnonymousID() -> UUID {
        return anonymousID
    }
    
    public func identify(userID: String) {
        self.userID = userID
    }
    
    public func resetIdentity(rotateAnonymous: Bool = true) {
        self.userID = nil
        if rotateAnonymous {
            let newID = UUID()
            anonymousID = newID
            keychain.set(Data(newID.uuidString.utf8), for: anonymousKey)
        }
    }
}
