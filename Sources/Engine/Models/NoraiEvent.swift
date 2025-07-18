//
//  NoraiEvent.swift
//  Norai
//
//  Created by Amr on 02/06/2025.
//

import Foundation

public struct NoraiEvent: Codable, Sendable {
    public var id: UUID = UUID()
    public var type: EventType
    var timestamp: Date?
    var sessionId: UUID?
    var userId: String?
    
    // Rich context information
    var context: EventContext = EventContext()
    
    // Device and app metadata  
    var metadata: EventMetadata = EventMetadata()
    
    // Event categorization
    var tags: [String] = []
    
    // Related state dependencies
    var dependencies: [EventDependency] = []
    
    // Legacy metadata for backward compatibility
    var metaData: [String: CodableValue] = [:]
    
    public init(
        id: UUID = UUID(),
        type: EventType,
        timestamp: Date? = nil,
        sessionId: UUID? = nil,
        userId: String? = nil,
        context: EventContext = EventContext(),
        metadata: EventMetadata = EventMetadata(),
        tags: [String] = [],
        dependencies: [EventDependency] = [],
        metaData: [String : CodableValue] = [:]
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.sessionId = sessionId
        self.userId = userId
        self.context = context
        self.metadata = metadata
        self.tags = tags
        self.dependencies = dependencies
        self.metaData = metaData
    }
}

// MARK: - Supporting Structures

public struct EventContext: Codable, Sendable {
    var screen: String?
    var component: String?
    var itemId: String?
    var visibilityRatio: Double?
    var viewDuration: Double?
    var position: Int?
    var totalItems: Int?
    
    public init(
        screen: String? = nil,
        component: String? = nil,
        itemId: String? = nil,
        visibilityRatio: Double? = nil,
        viewDuration: Double? = nil,
        position: Int? = nil,
        totalItems: Int? = nil
    ) {
        self.screen = screen
        self.component = component
        self.itemId = itemId
        self.visibilityRatio = visibilityRatio
        self.viewDuration = viewDuration
        self.position = position
        self.totalItems = totalItems
    }
}

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

public struct EventDependency: Codable, Sendable {
    let key: String
    let value: CodableValue
    
    public init(key: String, value: CodableValue) {
        self.key = key
        self.value = value
    }
}
