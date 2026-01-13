//
//  NavigationModifier.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import Foundation
import SwiftUI

/// 네비게이션 타이틀 수정자
struct NavigationModifier: ViewModifier {
    
    let naviTitle: Navititle
    let displayMode: NavigationBarItem.TitleDisplayMode
    
    enum Navititle: String {
        case signUp = "회원가입"
    }
    
    func body(content: Content) -> some View {
        content
            .navigationTitle(naviTitle.rawValue)
            .navigationBarTitleDisplayMode(displayMode)
    }
}

extension View {
    func navigation(naviTitle: NavigationModifier.Navititle, displayMode: NavigationBarItem.TitleDisplayMode) -> some View {
        self.modifier(NavigationModifier(naviTitle: naviTitle, displayMode: displayMode))
    }
}
