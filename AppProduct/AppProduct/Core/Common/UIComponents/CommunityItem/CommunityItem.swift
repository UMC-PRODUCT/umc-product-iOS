//
//  CommunityItem.swift
//  AppProduct
//
//  Created by 김미주 on 1/8/26.
//

import SwiftUI

// MARK: - Constants

private enum Constant {
    static let mainPadding: EdgeInsets = .init(top: 24, leading: 24, bottom: 24, trailing: 24)
    static let concentricRadius: CGFloat = 40
    static let mainVSpacing: CGFloat = 24
    // tag + status
    static let tagPadding: EdgeInsets = .init(top: 4, leading: 8, bottom: 4, trailing: 8)
    static let statusPadding: EdgeInsets = .init(top: 4, leading: 8, bottom: 4, trailing: 8)
    // content
    static let contentVSpacing: CGFloat = 12
    // profile
    static let profileSize: CGSize = .init(width: 30, height: 30)
    // count
    static let bottomHSpacing: CGFloat = 8
    static let countIconSpacing: CGFloat = 4
}

// MARK: - CummunityItem

/// 커뮤니티 탭 - 리스트

struct CommunityItem: View {
    // MARK: - Properties

    private let model: CommunityItemModel

    // MARK: - Init

    init(model: CommunityItemModel) {
        self.model = model
    }

    // MARK: - Body

    var body: some View {
        CommunityItemPresenter(model: model)
            .equatable()
    }
}

// MARK: - Presenter

private struct CommunityItemPresenter: View, Equatable {
    let model: CommunityItemModel

    static func == (lhs: CommunityItemPresenter, rhs: CommunityItemPresenter) -> Bool {
        lhs.model == rhs.model
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constant.mainVSpacing) {
            TopSection(model: model)
            ContentSection(model: model)
            BottomSection(model: model)
        }
        .padding(Constant.mainPadding)
        .background(
            ContainerRelativeShape()
                .fill(.grey000)
        )
        .containerShape(.rect(cornerRadius: Constant.concentricRadius))
    }
}

// 태그 + 상태 + 시간
private struct TopSection: View, Equatable {
    let model: CommunityItemModel

    var body: some View {
        HStack {
            Text(model.category.text)
                .appFont(.caption1Emphasis, color: .indigo600)
                .padding(Constant.tagPadding)
                .glassEffect(.regular.tint(.indigo100))
            Text(model.tag.text)
                .appFont(.caption1Emphasis, color: .yellow700)
                .padding(Constant.statusPadding)
                .glassEffect(.regular.tint(.yellow100))
            Spacer()
            Text(model.createdAt)
                .appFont(.caption1, color: .grey500)
        }
    }
}

// 내용
private struct ContentSection: View, Equatable {
    let model: CommunityItemModel

    var body: some View {
        VStack(alignment: .leading, spacing: Constant.contentVSpacing) {
            Text(model.title)
                .appFont(.title2Emphasis, color: .grey900)

            Text(model.content)
                .appFont(.body, color: .grey600)
                .lineLimit(2)
        }
    }
}

// 작성자 + 좋아요 + 댓글
private struct BottomSection: View, Equatable {
    let model: CommunityItemModel

    var body: some View {
        HStack(spacing: Constant.bottomHSpacing) {
            // 프로필 이미지
            if model.profileImage != nil {
                model.profileImage
            } else {
                Text(model.userName.prefix(1))
                    .appFont(.caption2Emphasis, color: .grey500)
                    .frame(width: Constant.profileSize.width, height: Constant.profileSize.height)
                    .background(.grey100, in: Circle())
            }
            // 이름 + 파트
            Text("\(model.userName) • \(model.part)")

            Spacer()

            // 좋아요 + 댓글
            HStack(spacing: Constant.countIconSpacing) {
                Image(systemName: "heart")
                    .foregroundStyle(.red500)
                Text(String(model.likeCount))
            }
            HStack(spacing: Constant.countIconSpacing) {
                Image(systemName: "bubble")
                    .foregroundStyle(.indigo500)
                Text(String(model.commentCount))
            }
        }
        .appFont(.caption1Emphasis, color: .grey500)
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
