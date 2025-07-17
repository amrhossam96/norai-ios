//
//  DeviceInfoProcessor.swift
//  Norai
//
//  Created by Amr on 28/06/2025.
//

#if canImport(UIKit)
import UIKit

public struct DeviceInfoProcessor: NoraiEventProcessorProtocol {
    public init() {}

    public func process(events: [NoraiEvent]) async -> [NoraiEvent] {
        return events.map { event in
            var eventCopy = event
            
            // Add device info to event context
            eventCopy.context["device_model"] = UIDevice.current.model
            eventCopy.context["device_name"] = UIDevice.current.name
            eventCopy.context["system_version"] = UIDevice.current.systemVersion
            eventCopy.context["system_name"] = UIDevice.current.systemName
            
            return eventCopy
        }
    }
}
#endif
