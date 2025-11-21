//
//  DeviceMetadataProcessor.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import Foundation
#if os(iOS)
import UIKit
#endif

struct DeviceMetadataProcessor: NoraiEventProcessorProtocol {
    public init() {}
    func process(batch: NoraiEventBatch) async -> NoraiEventBatch {
        var processedBatch: NoraiEventBatch = batch
        processedBatch.metaData["device_model"] = await .string(UIDevice.current.model)
        processedBatch.metaData["os_name"] = await .string(UIDevice.current.systemName)
        processedBatch.metaData["os_version"] = await .string(UIDevice.current.systemVersion)
        processedBatch.metaData["screen_width"] = await .number(Double(Int(UIScreen.main.bounds.width)))
        processedBatch.metaData["screen_height"] = await .number(Double(Int(UIScreen.main.bounds.height)))
        processedBatch.metaData["locale"] = .string(Locale.current.identifier)
        processedBatch.metaData["battery_level"] = await .number(Double(UIDevice.current.batteryLevel))
        return processedBatch
    }
}
