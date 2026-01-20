//
//  CommunityLikeButton.swift
//  AppProduct
//
//  Created by 김미주 on 1/20/26.
//

import SwiftUI

struct CommunityLikeButton: View {
    @State var isLiked: Bool = false
    @State var count: Int

    var body: some View {
        Button(action: {
            isLiked.toggle()
            count = isLiked ? count + 1 : count - 1
            // TODO: 좋아요 API 연결 - [김미주] 26.01.20
        }) {
            HStack(spacing: DefaultSpacing.spacing4) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                Text("좋아요")
                Text(String(count))
            }
            .appFont(.subheadline, color: isLiked ? .red : .grey600)
        }
        .buttonStyle(.glass)
    }
}

#Preview {
    CommunityLikeButton(count: 2)
}
