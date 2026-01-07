//
//  LoadingViewModifier.swift
//  AppProduct
//
//  Created by 이예지 on 1/4/26.
//

import SwiftUI

// MARK: - LoadingViewModifier

struct LoadingViewModifier: ViewModifier {
    
    /// LoadingMessage
    enum LoadingMessage: String {
        case basicLoading = "이동중이에요!"
        case loginLoading = "로그인 중이에요!"
        case assignmentLoading = "과제를 제출하고 있어요!"
        case noticeLoading = "공지를 보내는 중이에요!"
    }
    
    let loadingMessage: LoadingMessage
    let controlSize: ControlSize
    
    func body(content: Content) -> some View {
        content
            .overlay(content: {
                ZStack {
                    Color.black.opacity(0.5)
                    
                    ProgressView(label: {
                        Text(loadingMessage.rawValue)
                    })
                    .controlSize(controlSize)
                }
            })
    }
}

// MARK: - LoadingView Extension

extension View {
    func loadingModifier(loadingMessage: LoadingViewModifier.LoadingMessage, controlSize: ControlSize) -> some View {
        self.modifier(LoadingViewModifier(loadingMessage: loadingMessage, controlSize: controlSize))
    }
}
