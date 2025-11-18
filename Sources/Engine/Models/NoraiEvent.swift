//
//  NoraiEvent.swift
//  Norai
//
//  Created by Amr Hossam on 18/11/2025.
//

import Foundation

struct NoraiEvent: Codable {
    public let eventType: String
    public let sessionID: UUID? = nil
    public var anonymousID: UUID?
    public var userID: String?
    public var createdAt: Date = .now
    public var properties: [String: JSONValue]
    public var context: [String: JSONValue]
    public var metaData: [String: JSONValue]
}
