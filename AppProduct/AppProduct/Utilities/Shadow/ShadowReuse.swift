//
//  ShadowReuse.swift
//  AppProduct
//
//  Created by euijjang97 on 1/13/26.
//

import Foundation
import SwiftUI

/// shadow1 modifier
struct Shadow1: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .grey900.opacity(0.03), radius: 4, x: 0, y: 8)
            .shadow(color: .grey900.opacity(0.03), radius: 2, x: 1, y: 3)
            .shadow(color: .grey900.opacity(0.03), radius: 3, x: 0, y: 2)
    }
}

/// glass modifier
struct Glass: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 8)
            .shadow(color: .black.opacity(0.03), radius: 2, x: 1, y: 3)
    }
}

struct BlurShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color(red: 0.56, green: 0.56, blue: 0.58).opacity(0.05), radius: 4, x: 0, y: -14)
    }
}

extension View {
    func shadow1() -> some View {
        self.modifier(Shadow1())
    }
    
    func glass() -> some View {
        self.modifier(Glass())
    }
    
    func blurShadow() -> some View {
        self.modifier(BlurShadow())
    }
}
