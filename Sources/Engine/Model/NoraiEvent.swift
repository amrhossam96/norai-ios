//
//  NoraiEvent.swift
//  Norai
//
//  Created by Amr on 02/06/2025.
//

import Foundation

public struct NoraiEvent: Encodable, Sendable {
    private let id: UUID
    private let type: EventType
    private let timestamp: Date
    private let sessionId: UUID
    private var userId: String?
    private let metaData: [String: CodableValue]
    
    public init(
        id: UUID,
        type: EventType,
        timestamp: Date,
        sessionId: UUID,
        userId: String? = nil,
        metaData: [String : CodableValue]
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.sessionId = sessionId
        self.userId = userId
        self.metaData = metaData
    }
}
