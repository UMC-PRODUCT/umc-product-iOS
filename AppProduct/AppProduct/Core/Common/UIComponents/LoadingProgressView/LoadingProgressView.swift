//
//  LoadingProgressView.swift
//  AppProduct
//
//  Created by 이예지 on 1/22/26.
//

import SwiftUI

struct LoadingProgressView: View {
    
    // MARK: - Property
    let progressSize: ControlSize
    let progressColor: Color
    let message: String
    let messageColor: Color
    let messageSize: Font
    
    // MARK: - Initializer
    init(progressSize: ControlSize = .regular,
         progressColor: Color = .indigo500,
         message: String,
         messageColor: Color = .grey900,
         messageSize: Font = .callout) {
        self.progressSize = progressSize
        self.progressColor = progressColor
        self.message = message
        self.messageColor = messageColor
        self.messageSize = messageSize
    }
    
    // MARK: - Constant
    fileprivate enum Constants {
        static let vstackSpacing: CGFloat = 10
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: Constants.vstackSpacing, content: {
            ProgressView()
                .controlSize(progressSize)
            Text(message)
                .foregroundStyle(messageColor)
            //    .appFont(message)
        })
    }
}

// MARK: - Preview
#Preview(traits: .sizeThatFitsLayout) {
    LoadingProgressView(message: "로딩중")
}
