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

    public func process(event: NoraiEvent, timestamp: Date) async -> NoraiEvent {
        var eventCopy = event
        
        return eventCopy
    }
}
#endif
