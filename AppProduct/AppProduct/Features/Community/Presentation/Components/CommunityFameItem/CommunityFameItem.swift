//
//  CommunityFameItem.swift
//  AppProduct
//
//  Created by 김미주 on 1/10/26.
//

import SwiftUI

// MARK: - Constant

private enum Constant {
    static let buttonPadding: EdgeInsets = .init(top: 8, leading: 12, bottom: 8, trailing: 12)
    // profile
    static let profileCircleSize: CGSize = .init(width: 40, height: 40)
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
        .padding(DefaultConstant.defaultCardPadding)
        .background {
            ConcentricRectangle(corners: .concentric(minimum: DefaultConstant.concentricRadius), isUniform: true)
                .fill(.white)
                .glass()
        }
    }

    // MARK: - Section

    private var profileSection: some View {
        HStack(spacing: DefaultSpacing.spacing16) {
            RemoteImage(urlString: model.profileImage ?? "", size: Constant.profileCircleSize)

            VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
                // 이름 + 파트
                HStack(spacing: DefaultSpacing.spacing8) {
                    Text(model.userName)
                        .appFont(.calloutEmphasis, color: .grey900)
                    Text(model.part.name)
                        .appFont(.footnote, color: .grey600)
                        .padding(Constant.partTagPadding)
                        .background(.white, in: RoundedRectangle(cornerRadius: Constant.partTagRadius))
                        .overlay(RoundedRectangle(cornerRadius: Constant.partTagRadius).strokeBorder(.gray))
                }

                // 워크북
                Text(model.workbookTitle)
                    .appFont(.subheadline, color: .gray)
            }
        }
    }

    // 보기 버튼
    private var btnSection: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("보기")
            }
        }
        .appFont(.subheadline, color: .grey900)
        .padding(Constant.buttonPadding)
        .glassEffect(.clear.interactive())
    }

    // 피드백 내용
    private var feedbackSection: some View {
        Text(model.content.forceCharWrapping)
            .appFont(.subheadline, color: .grey700)
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
            part: .front(type: .web),
            workbookTitle: "React Todo List 만들기",
            content: "컴포넌트 분리가 매우 잘 되어있고, 상태 관리가 깔끔합니다."
        ),
        action: {
            print("1번 리스트")
        }
    )
}
