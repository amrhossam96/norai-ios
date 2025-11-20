//
//  DeviceMetadataEnricher.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import Foundation
#if os(iOS)
import UIKit
#endif

struct DeviceMetadataEnricher: NoraiEventEnricherProtocol {
    public init() {}
    
    func enrich(event: NoraiEvent) async -> NoraiEvent {
        var enrichedEvent = event
        enrichedEvent.metaData["device_model"] = await .string(UIDevice.current.model)
        enrichedEvent.metaData["os_name"] = await .string(UIDevice.current.systemName)
        enrichedEvent.metaData["os_version"] = await .string(UIDevice.current.systemVersion)
        enrichedEvent.metaData["screen_width"] = await .number(Double(Int(UIScreen.main.bounds.width)))
        enrichedEvent.metaData["screen_height"] = await .number(Double(Int(UIScreen.main.bounds.height)))
        enrichedEvent.metaData["locale"] = .string(Locale.current.identifier)
        enrichedEvent.metaData["battery_level"] = await .number(Double(UIDevice.current.batteryLevel))
        return enrichedEvent
    }
}

