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

    public func process(event: NoraiEvent) async -> NoraiEvent {
        var eventCopy = event
        eventCopy.metaData["deviceModel"] = await .string(UIDevice.current.model)
        eventCopy.metaData["osVersion"] = await .string(UIDevice.current.systemVersion)
        eventCopy.metaData["deviceName"] = await .string(UIDevice.current.name)
        eventCopy.metaData["systemName"] = await .string(UIDevice.current.systemName)
        return eventCopy
    }
}
#endif
