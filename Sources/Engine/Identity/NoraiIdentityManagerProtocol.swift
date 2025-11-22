//
//  NoraiIdentityManagerProtocol.swift
//  Norai
//
//  Created by Amr Hossam on 18/11/2025.
//

import Foundation

protocol NoraiIdentityManagerProtocol: Sendable {
    func identify(userID: String) async
    func logout() async
    func currentIdentity() async -> (userID: String?, anonymousID: UUID)
}


