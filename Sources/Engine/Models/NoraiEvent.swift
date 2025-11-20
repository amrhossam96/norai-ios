//
//  NoraiEvent.swift
//  Norai
//
//  Created by Amr Hossam on 18/11/2025.
//

import Foundation

public struct NoraiEvent: Codable {

    public let eventType: String
    public var sessionID: UUID? = nil
    public var anonymousID: UUID?
    public var userID: String?
    public var createdAt: Date = .now
    public var properties: [String: JSONValue]
    public var context: [String: JSONValue]
    public var metaData: [String: JSONValue]

    enum CodingKeys: String, CodingKey {
        case eventType = "event_type"
        case sessionID = "session_id"
        case anonymousID = "anonymous_id"
        case userID = "user_id"
        case createdAt = "created_at"
        case properties
        case context
        case metaData = "metadata"
    }
}
