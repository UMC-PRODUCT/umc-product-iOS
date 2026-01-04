//
//  LoadingView.swift
//  AppProduct
//
//  Created by 이예지 on 1/4/26.
//

import SwiftUI

// MARK: - LoadingView

struct LoadingView<Content: View>: View {
    
    // MARK: - Properties
    private let content: Content
    
    @Environment(\.loadingViewIsPresented) private var isPresented
    @Environment(\.loadingViewMessage) private var message
    @Environment(\.loadingViewSize) private var size
    
    // MARK: - Initializer
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            content
            
            if isPresented {
                LoadingViewContent(message: message, size: size)
                    .equatable()
            }
        }
    }
}

// MARK: - LoadingViewContent (Presenter)
private struct LoadingViewContent: View, Equatable {
    let message: String?
    let size: LoadingViewSize
    
    static func == (lhs: LoadingViewContent, rhs: LoadingViewContent) -> Bool {
        lhs.message == rhs.message &&
        lhs.size == rhs.size
    }
    
    var body: some View {
        VStack(spacing: 10) {
            ProgressView()
                .progressViewStyle(.circular)
                .frame(width: size.size.width , height: size.size.height)
            
            if let message {
                Text(message)
                    .font(size.font)
            }
        }
    }
}


// MARK: - LoadingView + AnyLoadingView

extension LoadingView: AnyLoadingView { }

// MARK: - Preview

#Preview("Loading ON + Message + Size") {
    LoadingView {
        RoundedRectangle(cornerRadius: 16)
            .foregroundStyle(Color.accent100)
            .frame(height: 160)
            .overlay { Text("Content") }
            .padding()
    }
    .presented(.constant(true))
}
