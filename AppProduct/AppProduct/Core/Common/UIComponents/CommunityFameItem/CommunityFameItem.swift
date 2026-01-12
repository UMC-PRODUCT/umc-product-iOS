//
//  CommunityFameItem.swift
//  AppProduct
//
//  Created by 김미주 on 1/10/26.
//

import SwiftUI

// MARK: - Constant

private enum Constant {
    static let mainVSpacing: CGFloat = 24
    static let mainPadding: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
    static let mainRadius: CGFloat = 20
    // profile
    static let profileCircleSize: CGSize = .init(width: 39, height: 39)
    static let nameHSpacing: CGFloat = 8
    static let partTagPadding: EdgeInsets = .init(top: 2, leading: 8, bottom: 2, trailing: 8)
    static let partTagRadius: CGFloat = 8
    // button
    static let buttonIconSize: CGFloat = 16
    static let buttonSize: CGSize = .init(width: 64, height: 32)
    static let buttonRadius: CGFloat = 8
    // feedback
    static let feedbackPadding: EdgeInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)
    static let feedbackRadius: CGFloat = 10
}

// MARK: - CommunityFameItem

/// 커뮤니티탭 - 명예의전당 리스트

struct CommunityFameItem: View {
    // MARK: - Properties

    private let model: CommunityFameItemModel
    private let action: () -> Void

    // MARK: - Init

    init(model: CommunityFameItemModel, action: @escaping () -> Void) {
        self.model = model
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        CommunityFameItemPresenter(model: model, action: action)
    }
}

// MARK: - Presenter

private struct CommunityFameItemPresenter: View, Equatable {
    let model: CommunityFameItemModel
    let action: () -> Void

    static func == (lhs: CommunityFameItemPresenter, rhs: CommunityFameItemPresenter) -> Bool {
        lhs.model == rhs.model
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constant.mainVSpacing) {
            HStack {
                ProfileSection(model: model)

                Spacer()

                // 보기 버튼
                Button(action: action) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: Constant.buttonIconSize))
                    Text("보기")
                        .appFont(.caption1)
                }
                .foregroundStyle(.black)
                .frame(width: Constant.buttonSize.width, height: Constant.buttonSize.height)
                .background(.white, in: RoundedRectangle(cornerRadius: Constant.buttonRadius))
                .overlay(RoundedRectangle(cornerRadius: Constant.buttonRadius).strokeBorder(.gray))
            }

            // 피드백 내용
            Text(model.content)
                .appFont(.caption1, color: .grey700)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Constant.feedbackPadding)
                .background(.grey100, in: RoundedRectangle(cornerRadius: Constant.feedbackRadius))
        }
        .padding(Constant.mainPadding)
        .background(.white, in: RoundedRectangle(cornerRadius: Constant.mainRadius))
    }
}

// 프로필
private struct ProfileSection: View, Equatable {
    let model: CommunityFameItemModel

    var body: some View {
        if model.profileImage != nil {
            model.profileImage
        } else {
            Text(model.userName.prefix(1))
                .appFont(.callout, color: .black)
                .frame(width: Constant.profileCircleSize.width, height: Constant.profileCircleSize.height)
                .background(.grey100, in: Circle())
        }

        VStack(alignment: .leading) {
            // 이름 + 파트
            HStack(spacing: Constant.nameHSpacing) {
                Text(model.userName)
                    .appFont(.subheadlineEmphasis, color: .black)
                Text(model.part)
                    .appFont(.caption2, color: .gray)
                    .padding(Constant.partTagPadding)
                    .background(.white, in: RoundedRectangle(cornerRadius: Constant.partTagRadius))
                    .overlay(RoundedRectangle(cornerRadius: Constant.partTagRadius).strokeBorder(.gray))
            }

            // 워크북
            Text(model.workbookTitle)
                .appFont(.caption1, color: .gray)
        }
    }
}

#Preview {
    CommunityFameItem(
        model: .init(
            profileImage: nil,
            userName: "김멋사",
            part: "Web",
            workbookTitle: "React Todo List 만들기",
            content: "컴포넌트 분리가 매우 잘 되어있고, 상태 관리가 깔끔합니다."
        ),
        action: {
            print("1번 리스트")
        }
    )
}
