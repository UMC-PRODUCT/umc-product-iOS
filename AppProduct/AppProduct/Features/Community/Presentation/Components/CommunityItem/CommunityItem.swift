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
    private let action: () -> Void

    private enum Constant {
        // tag + status
        static let tagPadding: EdgeInsets = .init(top: 4, leading: 8, bottom: 4, trailing: 8)
        // profile
        static let profileSize: CGSize = .init(width: 30, height: 30)
    }

    // MARK: - Init

    init(model: CommunityItemModel, action: @escaping () -> Void) {
        self.model = model
        self.action = action
    }

    static func == (lhs: CommunityItem, rhs: CommunityItem) -> Bool {
        lhs.model == rhs.model
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
                topSection
                contentSection
                bottomSection
            }
            .padding(DefaultConstant.defaultCardPadding)
            .background {
                ConcentricRectangle(corners: .concentric(minimum: DefaultConstant.concentricRadius), isUniform: true)
                    .fill(.white)
                    .glass()
                
            }
        }
    }

    // MARK: - Top

    // 태그 + 상태 + 시간
    private var topSection: some View {
        HStack {
            Text(model.category.text)
                .appFont(.footnoteEmphasis, color: .grey700)
                .padding(Constant.tagPadding)
                .glassEffect(.clear.tint(model.category.color))

            Spacer()
            Text(model.createdAt)
                .appFont(.footnote, color: .grey500)
        }
    }

    // MARK: - Content

    // 내용
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            Text(model.title)
                .appFont(.calloutEmphasis, color: .grey900)
                .lineLimit(1)

            Text(model.content)
                .appFont(.subheadline, color: .grey600)
                .lineLimit(2)
        }
    }

    // MARK: - Bottom

    // 작성자 + 좋아요 + 댓글
    private var bottomSection: some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            // 프로필 이미지
            if model.profileImage != nil {
                // !!! - url 이미지 처리
                Image(systemName: "heart")
            } else {
                Text(model.userName.prefix(1))
                    .appFont(.caption1Emphasis, color: .grey500)
                    .frame(width: Constant.profileSize.width, height: Constant.profileSize.height)
                    .background(.grey100, in: Circle())
            }
            // 이름 + 파트
            Text("\(model.userName) • \(model.part.name)")

            Spacer()

            // 좋아요 + 댓글
            HStack(spacing: DefaultSpacing.spacing4) {
                Image(systemName: "heart")
                    .foregroundStyle(.red)
                Text(String(model.likeCount))
            }
            HStack(spacing: DefaultSpacing.spacing4) {
                Image(systemName: "bubble")
                    .foregroundStyle(.indigo500)
                Text(String(model.commentCount))
            }
        }
        .appFont(.footnote, color: .grey500)
    }
}

#Preview {
    CommunityItem(model: .init(userId: 0, category: .hobby, title: "안녕하세요", content: "안녕하세요요용", profileImage: nil, userName: "제옹", part: .front(type: .ios), createdAt: "12123", likeCount: 1, commentCount: 1), action: {})
}
