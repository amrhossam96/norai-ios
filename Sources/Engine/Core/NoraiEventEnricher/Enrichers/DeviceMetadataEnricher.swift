//
//  DeviceMetadataEnricher.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

#if canImport(UIKit)
import UIKit
#endif
import Foundation

public struct DeviceMetadataEnricher: NoraiEventEnricherProtocol {
    public init() {}
    
    public func enrich(event: NoraiEvent, with state: NoraiEngineState) async -> NoraiEvent {
        var enrichedEvent = event
        
        // App metadata (safe to access from any thread)
        enrichedEvent.metadata.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        enrichedEvent.metadata.platform = "iOS"
        
        // System info (requires main actor)
        #if canImport(UIKit)
        await MainActor.run {
            enrichedEvent.metadata.osVersion = UIDevice.current.systemVersion
            enrichedEvent.metadata.deviceModel = UIDevice.current.model
            
            // Screen size
            let screen = UIScreen.main.bounds
            enrichedEvent.metadata.screenSize = "\(Int(screen.width))x\(Int(screen.height))"
        }
        #endif
        
        // Locale and timezone (safe to access from any thread)
        enrichedEvent.metadata.locale = Locale.current.identifier
        enrichedEvent.metadata.timezone = TimeZone.current.identifier
        
        return enrichedEvent
    }
} 
