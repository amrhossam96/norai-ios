//
//  TrackingPropertiesPreferenceKey.swift
//  Norai
//
//  Created by Amr Hossam on 21/07/2025.
//

import SwiftUI

struct TrackingPropertiesPreferenceKey: PreferenceKey {
    static var defaultValue: [AnyHashable: [String: String]] = [:]
    
    static func reduce(value: inout [AnyHashable: [String : String]],
                       nextValue: () -> [AnyHashable : [String : String]]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

