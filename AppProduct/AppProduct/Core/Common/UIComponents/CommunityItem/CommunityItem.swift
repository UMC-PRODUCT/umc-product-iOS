//
//  CommunityItem.swift
//  AppProduct
//
//  Created by 김미주 on 1/8/26.
//

import SwiftUI

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
    }
}

// MARK: - Presenter

private struct CommunityItemPresenter: View, Equatable {
    let model: CommunityItemModel

    static func == (lhs: CommunityItemPresenter, rhs: CommunityItemPresenter) -> Bool {
        lhs.model == rhs.model
    }

    var body: some View {
        VStack(alignment: .leading) {
            // 태그 + 상태
            HStack {
                Text(model.tag.text)
                    .font(.system(size: 12))
                    .padding(.vertical, 3)
                    .padding(.horizontal, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.gray.opacity(0.2))
                            .strokeBorder(.gray)
                    )
                Spacer()
                Text(model.status.text)
                    .font(.system(size: 10))
                    .foregroundStyle(model.status.mainColor)
                    .padding(.vertical, 3)
                    .padding(.horizontal, 7)
                    .background(
                        Capsule()
                            .fill(model.status.subColor)
                    )
            }

            // 내용
            VStack(alignment: .leading, spacing: 4) {
                Text(model.title)
                    .font(.system(size: 16).bold())

                HStack(spacing: 8) {
                    Text(model.location)
                    Text("•")
                    Text(model.userName)
                    Text("•")
                    Text(model.createdAt)
                }
                .font(.system(size: 12))
                .foregroundStyle(.gray)
            }

            Divider()

            // 좋아요 + 댓글
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "heart")
                        .resizable()
                        .frame(width: 12, height: 12)
                    Text(String(model.likeCount))
                        .font(.system(size: 12))
                }

                HStack(spacing: 4) {
                    Image(systemName: "bubble")
                        .resizable()
                        .frame(width: 12, height: 12)
                    Text(String(model.commentCount))
                        .font(.system(size: 12))
                }
            }
            .foregroundStyle(.gray)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
        )
    }
}

#Preview {
    struct CommunityItemPreview: View {
        var body: some View {
            ZStack {
                Color.grey100

                CommunityItem(
                    model: .init(
                        tag: .question,
                        status: .recruiting,
                        title: "React Hook 질문있습니다",
                        location: "서울",
                        userName: "이코딩",
                        createdAt: "1시간 전",
                        likeCount: 5,
                        commentCount: 3
                    )
                )
                .padding()
            }
        }
    }

    return CommunityItemPreview()
}
