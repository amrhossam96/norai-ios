//
//  NoraiEvent.swift
//  Norai
//
//  Created by Amr on 02/06/2025.
//

import Foundation

public struct NoraiEvent: Codable, Sendable, Equatable {
    public var id: UUID = UUID()
    public var event: String
    public var timestamp: Date?
    public var sessionId: UUID?
    public var userId: String?

    public var properties: [String: String] = [:]
    
    public var context: [String: String] = [:]
    
    // Device and app metadata (auto-codable)
    public var metadata: EventMetadata = EventMetadata()
    
    // Event categorization (auto-codable)
    public var tags: [String] = []
    
    public init(
        id: UUID = UUID(),
        event: String,
        timestamp: Date? = nil,
        sessionId: UUID? = nil,
        userId: String? = nil,
        properties: [String: String] = [:],
        context: [String: String] = [:],
        metadata: EventMetadata = EventMetadata(),
        tags: [String] = []
    ) {
        self.id = id
        self.event = event
        self.timestamp = timestamp
        self.sessionId = sessionId
        self.userId = userId
        self.properties = properties
        self.context = context
        self.metadata = metadata
        self.tags = tags
    }
}

// MARK: - Supporting Structures

public struct EventMetadata: Codable, Sendable, Equatable {
    var appVersion: String?
    var platform: String?
    var osVersion: String?
    var deviceModel: String?
    var locale: String?
    var networkType: String?
    var timezone: String?
    
    public init(
        appVersion: String? = nil,
        platform: String? = nil,
        osVersion: String? = nil,
        deviceModel: String? = nil,
        locale: String? = nil,
        networkType: String? = nil,
        timezone: String? = nil
    ) {
        self.appVersion = appVersion
        self.platform = platform
        self.osVersion = osVersion
        self.deviceModel = deviceModel
        self.locale = locale
        self.networkType = networkType
        self.timezone = timezone
    }
}

