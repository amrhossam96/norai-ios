//
//  VisibilityModifier.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import SwiftUI

struct VisibilityModifier<ID: Hashable>: ViewModifier {
    let id: ID

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(
                            key: ViewFramePreferenceKey.self,
                            value: [
                                ViewFrame(id: id, frame: proxy.frame(in: .named("noraiScroll")))
                            ]
                        )
                }
            )
    }
}

extension View {
    func trackVisibility<ID: Hashable>(id: ID) -> some View {
        self.modifier(VisibilityModifier(id: id))
    }
}

