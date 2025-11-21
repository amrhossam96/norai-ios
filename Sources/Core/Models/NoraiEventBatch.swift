//
//  NoraiEventBatch.swift
//  Norai
//
//  Created by Amr Hossam on 21/11/2025.
//

import Foundation

struct NoraiEventBatch: Codable {
    var events: [NoraiEvent]
    var metaData: [String: JSONValue]
}
