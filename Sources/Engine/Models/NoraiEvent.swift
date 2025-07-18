//
//  NoraiEvent.swift
//  Norai
//
//  Created by Amr on 02/06/2025.
//

import Foundation

public struct NoraiEvent: Codable, Sendable {
    public var id: UUID = UUID()
    public var event: String
    var timestamp: Date?
    var sessionId: UUID?
    var userId: String?
    
    // Business properties - what happened
    var properties: [String: String] = [:]
    
    // UI/UX context - how/where it happened  
    var context: [String: String] = [:]
    
    // Device and app metadata (auto-codable)
    var metadata: EventMetadata = EventMetadata()
    
    // Event categorization (auto-codable)
    var tags: [String] = []
    
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

public struct EventMetadata: Codable, Sendable {
    var appVersion: String?
    var platform: String?
    var osVersion: String?
    var deviceModel: String?
    var locale: String?
    var networkType: String?
    var timezone: String?
    var screenSize: String?
    
    public init(
        appVersion: String? = nil,
        platform: String? = nil,
        osVersion: String? = nil,
        deviceModel: String? = nil,
        locale: String? = nil,
        networkType: String? = nil,
        timezone: String? = nil,
        screenSize: String? = nil
    ) {
        self.appVersion = appVersion
        self.platform = platform
        self.osVersion = osVersion
        self.deviceModel = deviceModel
        self.locale = locale
        self.networkType = networkType
        self.timezone = timezone
        self.screenSize = screenSize
    }
}
