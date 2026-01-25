//
//  CommunityPostCard.swift
//  AppProduct
//
//  Created by 김미주 on 1/26/26.
//

import SwiftUI

struct CommunityPostCard: View {
    // MARK: - Properties

    private let model: CommunityItemModel
    @State private var isLiked: Bool

    private enum Constant {
        static let mainPadding: EdgeInsets = .init(top: 16, leading: 16, bottom: 24, trailing: 16)
        static let profileSize: CGSize = .init(width: 40, height: 40)
        static let contentPadding: EdgeInsets = .init(top: 8, leading: 0, bottom: 12, trailing: 0)
        static let buttonPadding: EdgeInsets = .init(top: 4, leading: 8, bottom: 4, trailing: 8)
    }

    // MARK: - Init

    init(model: CommunityItemModel) {
        self.model = model
        self._isLiked = State(initialValue: model.isLiked)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing24) {
            topSection

            Text(model.title)
                .appFont(.title2Emphasis, color: .black)

            profileSection

            Text(model.content)
                .appFont(.callout, color: .grey700)
                .padding(Constant.contentPadding)

            buttonSection
        }
        .padding(Constant.mainPadding)
        .background(
            RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
                .fill(.white)
        )
        .glass()
    }

    // MARK: - Section

    private var topSection: some View {
        HStack {
            CommunityTagItem(title: model.category.text)
            Spacer()
            Text(model.createdAt)
                .appFont(.footnote, color: .grey500)
        }
    }

    private var profileSection: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            // 프로필 이미지
            if model.profileImage != nil {
                // !!! - url 이미지 처리
                Image(systemName: "heart")
            } else {
                Text(model.userName.prefix(1))
                    .appFont(.body, color: .grey500)
                    .frame(width: Constant.profileSize.width, height: Constant.profileSize.height)
                    .background(.grey100, in: Circle())
            }

            VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                Text(model.userName)
                    .appFont(.subheadlineEmphasis, color: .black)
                Text(model.part)
                    .appFont(.footnote, color: .grey500)
            }
        }
    }

    private var buttonSection: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            makeButton(type: .like, isSelected: isLiked) {
                isLiked.toggle()
                // TODO: 좋아요 API
            }
            makeButton(type: .comment, isSelected: false) {
                // TODO: 댓글
            }
        }
    }

    // MARK: - Function

    private func makeButton(type: CommunityButtonType, isSelected: Bool, action: @escaping () -> Void) -> some View {
        let count: Int = {
            switch type {
            case .like: return model.likeCount
            case .comment: return model.commentCount
            }
        }()

        return Button(action: action) {
            Image(systemName: isSelected ? type.filledIcon : type.icon)
            Text("\(count)")
        }
        .padding(Constant.buttonPadding)
        .appFont(.subheadline, color: type.foregroundColor)
        .glassEffect(.regular.tint(type.backgroundColor).interactive())
    }
}
