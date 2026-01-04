//
//  LoadingViewModifier.swift
//  AppProduct
//
//  Created by 이예지 on 1/4/26.
//

import SwiftUI

// MARK: - AnyLoadingView Protocol

/// LoadingView 전용 프로토콜
/// 이 프로토콜을 준수하는 View만 LoadingView modifier 사용 가능
protocol AnyLoadingView: View { }


// MARK: - ViewModifiers

struct LoadingViewSizeModifier: ViewModifier {
    let size: LoadingViewSize
    
    func body(content: Content) -> some View {
        content.environment(\.loadingViewSize, size)
    }
}

struct LoadingViewIsPresentedModifier: ViewModifier {
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        content.environment(\.loadingViewIsPresented, isPresented)
    }
}

struct LoadingViewMessageModifier: ViewModifier {
    let message: String
    
    func body(content: Content) -> some View {
        content.environment(\.loadingViewMessage, message)
    }
}

// MARK: - AnyLoadingView Extension

extension AnyLoadingView {
    
    /// 로딩 사이즈 설정
    /// - Parameter size: small, large
    func loadingSize(_ size: LoadingViewSize) -> some View {
        self.modifier(LoadingViewSizeModifier(size: size))
    }
    
    /// 로딩 isPresented
    func presented(_ isPresented: Binding<Bool>) -> some View {
        self.modifier(LoadingViewIsPresentedModifier(isPresented: isPresented))
    }
    
    /// 로딩 메시지 설정
    func loadingMessage(_ message: String) -> some View {
        self.modifier(LoadingViewMessageModifier(message: message))
    }
}
