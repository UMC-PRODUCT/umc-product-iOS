//
//  CommunityItem.swift
//  AppProduct
//
//  Created by 김미주 on 1/8/26.
//

import SwiftUI

// MARK: - Constants

private enum Constant {
    static let mainPadding: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
    static let mainBoxRadius: CGFloat = 20
    // tag + status
    static let tagPadding: EdgeInsets = .init(top: 3, leading: 7, bottom: 3, trailing: 7)
    static let tagRadius: CGFloat = 8
    static let statusPadding: EdgeInsets = .init(top: 3, leading: 7, bottom: 3, trailing: 7)
    // content
    static let contentVSpacing: CGFloat = 4
    // count
    static let countHSpacing: CGFloat = 12
    static let countIconSpacing: CGFloat = 4
    static let countIconSize: CGFloat = 12
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
        VStack(alignment: .leading) {
            TagSection(model: model)
            ContentSection(model: model)
            Divider()
            CountSection(model: model)
        }
        .padding(Constant.mainPadding)
        .background(.white, in: RoundedRectangle(cornerRadius: Constant.mainBoxRadius))
    }
}

// 태그 + 상태
private struct TagSection: View, Equatable {
    let model: CommunityItemModel

    var body: some View {
        HStack {
            Text(model.tag.text)
                .appFont(.caption1, color: .grey900)
                .padding(Constant.tagPadding)
                .background(.grey100, in: RoundedRectangle(cornerRadius: Constant.tagRadius))
            Spacer()
            Text(model.status.text)
                .appFont(.caption2, color: model.status.mainColor)
                .padding(Constant.statusPadding)
                .background(model.status.subColor, in: Capsule())
        }
    }
}

// 내용
private struct ContentSection: View, Equatable {
    let model: CommunityItemModel

    var body: some View {
        VStack(alignment: .leading, spacing: Constant.contentVSpacing) {
            Text(model.title)
                .appFont(.calloutEmphasis, color: .grey900)

            HStack {
                Text("\(model.location) • \(model.userName) • \(model.createdAt)")
            }
            .appFont(.caption1, color: .gray)
        }
    }
}

// 좋아요 + 댓글
private struct CountSection: View, Equatable {
    let model: CommunityItemModel

    var body: some View {
        HStack(spacing: Constant.countHSpacing) {
            HStack(spacing: Constant.countIconSpacing) {
                Image(systemName: "heart")
                    .font(.system(size: Constant.countIconSize))
                Text(String(model.likeCount))
            }

            HStack(spacing: Constant.countIconSpacing) {
                Image(systemName: "bubble")
                    .font(.system(size: Constant.countIconSize))
                Text(String(model.commentCount))
            }
        }
        .appFont(.caption1, color: .gray)
    }
}

#Preview {
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
}
