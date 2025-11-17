//
//  NoraiIdentityManagerProtocol.swift
//  Norai
//
//  Created by Amr Hossam on 17/11/2025.
//

import Foundation

public protocol NoraiIdentityManagerProtocol {
    func getAnonymousID() -> UUID
    func identify(userID: String)
    func resetIdentity(rotateAnonymous: Bool)
}
