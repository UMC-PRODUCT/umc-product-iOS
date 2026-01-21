//
//  CommunityCommentItem.swift
//  AppProduct
//
//  Created by 김미주 on 1/20/26.
//

import SwiftUI

struct CommunityCommentItem: View {
    // MARK: - Properties

    private let model: CommunityCommentModel

    private enum Constant {
        static let profileSize: CGSize = .init(width: 32, height: 32)
        static let bubbleRadius: CGFloat = 20
        static let bubblePadding: EdgeInsets = .init(top: 12, leading: 16, bottom: 12, trailing: 16)
    }

    // MARK: - Init

    init(model: CommunityCommentModel) {
        self.model = model
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: DefaultSpacing.spacing12) {
            if model.profileImage != nil {
                model.profileImage
            } else {
                Text(model.userName.prefix(1))
                    .appFont(.body, color: .grey500)
                    .frame(width: Constant.profileSize.width, height: Constant.profileSize.height)
                    .background(.grey100, in: Circle())
            }

            BubbleSection
        }
    }

    // MARK: - Section

    private var BubbleSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            HStack {
                Text(model.userName)
                    .appFont(.subheadlineEmphasis)
                Spacer()
                Text(model.createdAt)
                    .appFont(.footnote, color: .grey600)
            }
            Text(model.content)
                .appFont(.subheadline)
        }
        .padding(Constant.bubblePadding)
        .background(.grey100, in: RoundedRectangle(cornerRadius: Constant.bubbleRadius))
    }
}

#Preview {
    CommunityCommentItem(model: .init(profileImage: nil, userName: "김애플", content: "저 참여하고 싶습니다! 아직 자리 있나요?", createdAt: "10분 전"))
}
