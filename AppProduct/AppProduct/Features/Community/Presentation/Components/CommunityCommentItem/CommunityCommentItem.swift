//
//  CommunityCommentItem.swift
//  AppProduct
//
//  Created by 김미주 on 1/20/26.
//

import SwiftUI

struct CommunityCommentItem: View, Equatable {
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

    static func == (lhs: CommunityCommentItem, rhs: CommunityCommentItem) -> Bool {
        lhs.model == rhs.model
    }
    
    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: DefaultSpacing.spacing12) {
            RemoteImage(urlString: model.profileImage ?? "", size: Constant.profileSize)

            bubbleSection
        }
    }

    // MARK: - Section

    private var bubbleSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            HStack {
                Text(model.userName)
                    .appFont(.subheadlineEmphasis, color: .black)
                Spacer()
                Text(model.createdAt.timeAgoText)
                    .appFont(.footnote, color: .grey500)
            }
            Text(model.content)
                .appFont(.subheadline, color: .grey700)
        }
        .padding(Constant.bubblePadding)
        .background(.grey100, in: RoundedRectangle(cornerRadius: Constant.bubbleRadius))
    }
}
