//
//  ScrollViewFrameKey.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import SwiftUI

struct ScrollViewFrameKey: @preconcurrency PreferenceKey {
    @MainActor static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

