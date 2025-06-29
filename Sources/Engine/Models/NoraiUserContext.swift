//
//  NoraiUserContext.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation

public struct NoraiUserContext: Sendable {
    var id: String?
    var anonymousId: String?
    var firstName: String?
    var lastName: String?
    var email: String?
    var isLoggedIn: Bool = false
    
    public init(
        id: String? = nil,
        anonymousId: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        email: String? = nil,
        isLoggedIn: Bool
    ) {
        self.id = id
        self.anonymousId = anonymousId
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.isLoggedIn = isLoggedIn
    }
}
