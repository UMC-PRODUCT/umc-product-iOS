//
//  Progress.swift
//  AppProduct
//
//  Created by 이예지 on 1/22/26.
//

import SwiftUI

struct Progress: View {
    
    // MARK: - Property
    let progressColor: Color
    let message: String
    let messageColor: Color
    var size: ProgressSize
    
    // MARK: - Initializer
    init(progressColor: Color = .indigo500,
         message: String,
         messageColor: Color = .grey900,
         size: ProgressSize = .large) {
        self.progressColor = progressColor
        self.message = message
        self.messageColor = messageColor
        self.size = size
    }
    
    // MARK: - Constant
    fileprivate enum Constants {
        static let vstackSpacing: CGFloat = 10
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: Constants.vstackSpacing, content: {
            ProgressView()
                .controlSize(size.controlSize)
                .tint(progressColor)
            Text(message)
                .foregroundStyle(messageColor)
                .appFont(size.messageSize)
        })
    }
}

// MARK: - Preview
#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 100) {
        Progress(message: "로딩중!", size: .small)
        
        Progress(message: "공지를 불러오고 있어요!", size: .regular)
        
        Progress(message: "잠시만 기다려주세요!", size: .large)
    }
}
