//
//  TrackingPropertiesModifier.swift
//  Norai
//
//  Created by Amr Hossam on 21/07/2025.
//

import SwiftUI

extension View {
    func withTrackingProperties<ID: Hashable>(_ id: ID, properties: [String: String]) -> some View {
        self
            .anchorPreference(key: TrackingPropertiesPreferenceKey.self, value: .bounds) { _ in
                            [AnyHashable(id): properties]
                        }
    }
}

