//
//  CommunityFameItem.swift
//  AppProduct
//
//  Created by 김미주 on 1/10/26.
//

import SwiftUI

// MARK: - Constant

private enum Constant {
    static let mainPadding: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
    // profile
    static let profileCircleSize: CGSize = .init(width: 39, height: 39)
    static let partTagPadding: EdgeInsets = .init(top: 2, leading: 8, bottom: 2, trailing: 8)
    static let partTagRadius: CGFloat = 8
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

    static func == (lhs: CommunityFameItem, rhs: CommunityFameItem) -> Bool {
        lhs.model == rhs.model
    }

    // MARK: - Init

    init(model: CommunityFameItemModel, action: @escaping () -> Void) {
        self.model = model
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing24) {
            HStack {
                profileSection
                Spacer()
                btnSection
            }
            feedbackSection
        }
        .padding(Constant.mainPadding)
        .containerShape(
            .rect(cornerRadius: DefaultConstant.defaultListCornerRadius)
        )
        .background(.white, in: .rect(cornerRadius: DefaultConstant.defaultCornerRadius))
        .glass()
    }

    // MARK: - Section

    private var profileSection: some View {
        HStack {
            if model.profileImage != nil {
                // !!! - url 이미지 처리
                Image(systemName: "heart")
            } else {
                Text(model.userName.prefix(1))
                    .appFont(.callout, color: .grey900)
                    .frame(width: Constant.profileCircleSize.width, height: Constant.profileCircleSize.height)
                    .background(.grey100, in: Circle())
            }

            VStack(alignment: .leading) {
                // 이름 + 파트
                HStack(spacing: DefaultSpacing.spacing8) {
                    Text(model.userName)
                        .appFont(.subheadlineEmphasis, color: .grey900)
                    Text(model.part)
                        .appFont(.footnote, color: .grey600)
                        .padding(Constant.partTagPadding)
                        .background(.white, in: RoundedRectangle(cornerRadius: Constant.partTagRadius))
                        .overlay(RoundedRectangle(cornerRadius: Constant.partTagRadius).strokeBorder(.gray))
                }

                // 워크북
                Text(model.workbookTitle)
                    .appFont(.footnote, color: .gray)
            }
        }
    }

    // 보기 버튼
    private var btnSection: some View {
        Button(action: action) {
            Image(systemName: "square.and.arrow.up")
            Text("보기")
        }
        .appFont(.footnote, color: .grey900)
        .buttonStyle(.glass)
    }

    // 피드백 내용
    private var feedbackSection: some View {
        Text(model.content)
            .appFont(.footnote, color: .grey700)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Constant.feedbackPadding)
            .background(.grey100, in: RoundedRectangle(cornerRadius: Constant.feedbackRadius))
    }
}

#Preview {
    CommunityFameItem(
        model: .init(
            week: 1,
            university: "서울대학교",
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
