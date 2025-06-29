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
        eventCopy.metaData?["deviceModel"] = .string(UIDevice.current.model)
        eventCopy.metaData?["osVersion"] = .string(UIDevice.current.systemVersion)
        eventCopy.metaData?["deviceName"] = .string(UIDevice.current.name)
        eventCopy.metaData?["systemName"] = .string(UIDevice.current.systemName)
        return eventCopy
    }
}
#endif
