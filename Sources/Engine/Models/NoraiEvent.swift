//
//  NoraiEvent.swift
//  Norai
//
//  Created by Amr on 02/06/2025.
//

import Foundation

public struct NoraiEvent: Codable, Sendable {
    var id: UUID = UUID()
    var type: EventType
    var timestamp: Date?
    var sessionId: UUID?
    var userId: String?
    var metaData: [String: CodableValue] = [:]
    
    public init(
        id: UUID = UUID(),
        type: EventType,
        timestamp: Date? = nil,
        sessionId: UUID? = nil,
        userId: String? = nil,
        metaData: [String : CodableValue] = [:]
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.sessionId = sessionId
        self.userId = userId
        self.metaData = metaData
    }
}
