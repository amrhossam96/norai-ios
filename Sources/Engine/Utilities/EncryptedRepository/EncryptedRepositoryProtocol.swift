//
//  KeychainWrapperProtocol.swift
//  Norai
//
//  Created by Amr Hossam on 17/11/2025.
//

import Foundation

public protocol EncryptedRepositoryProtocol: Sendable {
    func get(_ key: String) -> Data?
    func set(_ value: Data, for key: String)
    func delete(_ key: String)
}
