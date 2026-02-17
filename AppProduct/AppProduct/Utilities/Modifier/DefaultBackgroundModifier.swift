//
//  DefaultBackgroundModifier.swift
//  AppProduct
//
//  Created by Codex on 2/18/26.
//

import SwiftUI

struct DefaultBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(Color.grey100.opacity(0.55))
    }
}

extension View {
    func umcDefaultBackground() -> some View {
        modifier(DefaultBackgroundModifier())
    }
}
