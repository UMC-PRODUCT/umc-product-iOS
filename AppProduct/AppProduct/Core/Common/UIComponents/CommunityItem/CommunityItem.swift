//
//  CommunityItem.swift
//  AppProduct
//
//  Created by 김미주 on 1/8/26.
//

import SwiftUI

// MARK: - CummunityItem

/// 커뮤니티 탭 - 리스트

struct CommunityItem: View, Equatable {
    // MARK: - Properties

    private let model: CommunityItemModel

    private enum Constant {
        static let mainPadding: EdgeInsets = .init(top: 24, leading: 24, bottom: 24, trailing: 24)
        static let concentricRadius: CGFloat = 40
        // tag + status
        static let tagPadding: EdgeInsets = .init(top: 4, leading: 8, bottom: 4, trailing: 8)
        static let statusPadding: EdgeInsets = .init(top: 4, leading: 8, bottom: 4, trailing: 8)
        // profile
        static let profileSize: CGSize = .init(width: 30, height: 30)
    }

    // MARK: - Init

    init(model: CommunityItemModel) {
        self.model = model
    }

    static func == (lhs: CommunityItem, rhs: CommunityItem) -> Bool {
        lhs.model == rhs.model
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing24) {
            TopSection
            ContentSection
            BottomSection
        }
        .padding(Constant.mainPadding)
        .background(
            ContainerRelativeShape()
                .fill(.grey100)
        )
        .containerShape(.rect(cornerRadius: Constant.concentricRadius))
        .glass()
    }

    // MARK: - Top

    // 태그 + 상태 + 시간
    private var TopSection: some View {
        HStack {
            Text(model.category.text)
                .appFont(.subheadlineEmphasis, color: .indigo600)
                .padding(Constant.tagPadding)
                .glassEffect(.regular.tint(.indigo100))
            Text(model.tag.text)
                .appFont(.subheadlineEmphasis, color: .grey700)
                .padding(Constant.statusPadding)
                .glassEffect(.clear)
            Spacer()
            Text(model.createdAt)
                .appFont(.subheadline, color: .grey500)
        }
    }

    // MARK: - Content

    // 내용
    private var ContentSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing12) {
            Text(model.title)
                .appFont(.title2Emphasis, color: .grey900)
                .lineLimit(1)

            Text(model.content)
                .appFont(.headline, color: .grey600)
                .lineLimit(2)
        }
    }

    // MARK: - Bottom

    // 작성자 + 좋아요 + 댓글
    private var BottomSection: some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            // 프로필 이미지
            if model.profileImage != nil {
                model.profileImage
            } else {
                Text(model.userName.prefix(1))
                    .appFont(.caption1Emphasis, color: .grey500)
                    .frame(width: Constant.profileSize.width, height: Constant.profileSize.height)
                    .background(.grey100, in: Circle())
            }
            // 이름 + 파트
            Text("\(model.userName) • \(model.part)")

            Spacer()

            // 좋아요 + 댓글
            HStack(spacing: DefaultSpacing.spacing4) {
                Image(systemName: "heart")
                    .foregroundStyle(.red500)
                Text(String(model.likeCount))
            }
            HStack(spacing: DefaultSpacing.spacing4) {
                Image(systemName: "bubble")
                    .foregroundStyle(.indigo500)
                Text(String(model.commentCount))
            }
        }
        .appFont(.subheadlineEmphasis, color: .grey500)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    CommunityItem(
        model: .init(
            category: .question,
            tag: .feedback,
            title: "React Hook 질문있습니다",
            content: "useEffect 의존성 배열 관련해서 질문이 있습니다... 코드가 자꾸 무한 루프에 빠지는데 로직 점검 부탁드려요!",
            profileImage: nil,
            userName: "이코딩",
            part: "Web",
            createdAt: "1시간 전",
            likeCount: 5,
            commentCount: 3
        )
    )
}
