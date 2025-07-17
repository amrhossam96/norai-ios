//
//  ViewFramePreferenceKey.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import SwiftUI

struct ViewFramePreferenceKey: @preconcurrency PreferenceKey {
    @MainActor static let defaultValue: [ViewFrame] = []
    static func reduce(value: inout [ViewFrame], nextValue: () -> [ViewFrame]) {
        value.append(contentsOf: nextValue())
    }
}
