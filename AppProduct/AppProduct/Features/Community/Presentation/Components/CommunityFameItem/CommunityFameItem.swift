//
//  CommunityFameItem.swift
//  AppProduct
//
//  Created by 김미주 on 1/10/26.
//

import SwiftUI

// MARK: - CommunityFameItem

/// 커뮤니티탭 - 명예의전당 리스트

struct CommunityFameItem: View, Equatable {
    // MARK: - Properties

    private let model: CommunityFameItemModel
    private let action: () -> Void

    static func == (lhs: CommunityFameItem, rhs: CommunityFameItem) -> Bool {
        lhs.model == rhs.model
    }
    
    
    // MARK: - Constant

    private enum Constant {
        static let profileCircleSize: CGSize = .init(width: 44, height: 44)
        static let cardBorderRadius: CGFloat = 40
        static let cardBorderWidth: CGFloat = 1
        static let cardBorderOpacity: Double = 0.85

        static let partTagPadding: EdgeInsets = .init(top: 4, leading: 10, bottom: 4, trailing: 10)
        static let partTagConcentricRadius: Edge.Corner.Style = 20
        static let partTagBackgroundOpacity: Double = 0.14

        static let buttonPadding: EdgeInsets = .init(top: 12, leading: 8, bottom: 12, trailing: 8)
        static let buttonLabelSpacing: CGFloat = 2

        static let feedbackPadding: EdgeInsets = .init(top: 14, leading: 12, bottom: 14, trailing: 12)
        static let feedbackConcentricRadius: Edge.Corner.Style = 20
        static let feedbackLineSpacing: CGFloat = 2
        static let feedbackGlassTintOpacity: Double = 0.12
        static let feedbackBorderOpacity: Double = 0.85
        static let feedbackBorderWidth: CGFloat = 1
        static let feedbackShadowOpacity: Double = 0.05
        static let feedbackShadowRadius: CGFloat = 6
        static let feedbackShadowY: CGFloat = 2
        static let feedbackGradientColors: [Color] = [
            .white.opacity(0.96),
            .indigo500.opacity(0.035),
            .grey100.opacity(0.92)
        ]
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
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: Constant.cardBorderRadius)
                .strokeBorder(
                    Color.white.opacity(Constant.cardBorderOpacity),
                    lineWidth: Constant.cardBorderWidth
                )
        }
    }

    // MARK: - Section

    private var profileSection: some View {
        HStack(alignment: .center, spacing: DefaultSpacing.spacing16) {
            RemoteImage(urlString: model.profileImage ?? "", size: Constant.profileCircleSize)

            VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
                // 이름 + 파트
                HStack(spacing: DefaultSpacing.spacing8) {
                    Text(model.userName)
                        .appFont(.calloutEmphasis, color: .grey900)
                    partTag
                }

                // 워크북
                Text(model.workbookTitle)
                    .appFont(.subheadline, color: .gray)
                    .lineLimit(1)
            }
        }
    }

    // 보기 버튼
    private var btnSection: some View {
        Button(action: action) {
            Label("보기", systemImage: "square.and.arrow.up")
                .appFont(.subheadline, color: .indigo500)
                .padding(Constant.buttonPadding)
                .labelIconToTitleSpacing(Constant.buttonLabelSpacing)
        }
        .buttonBorderShape(.capsule)
        .glassEffect(.regular.tint(.grey100).interactive())
    }

    // 피드백 내용
    private var feedbackSection: some View {
        Text(model.content.forceCharWrapping)
            .appFont(.body, color: .grey900)
            .lineSpacing(Constant.feedbackLineSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Constant.feedbackPadding)
            .background(feedbackBackground)
            .glassEffect(
                .clear.tint(.white.opacity(Constant.feedbackGlassTintOpacity)),
                in: .rect(corners: .concentric(minimum: Constant.feedbackConcentricRadius), isUniform: true)
            )
            .overlay(
                ConcentricRectangle(corners: .concentric(minimum: Constant.feedbackConcentricRadius), isUniform: true)
                    .stroke(
                        Color.white.opacity(Constant.feedbackBorderOpacity),
                        lineWidth: Constant.feedbackBorderWidth
                    )
            )
            .shadow(
                color: .black.opacity(Constant.feedbackShadowOpacity),
                radius: Constant.feedbackShadowRadius,
                y: Constant.feedbackShadowY
            )
    }

    private var partTag: some View {
        Text(model.part.name)
            .appFont(.footnoteEmphasis, color: model.part.color)
            .padding(Constant.partTagPadding)
            .background(
                model.part.color.opacity(Constant.partTagBackgroundOpacity),
                in: ConcentricRectangle(
                    corners: .concentric(minimum: Constant.partTagConcentricRadius),
                    isUniform: true
                )
            )
            .glassEffect(
                .clear,
                in: .rect(corners: .concentric(minimum: Constant.partTagConcentricRadius), isUniform: true)
            )
    }

    private var cardBackground: some View {
        ConcentricRectangle(corners: .concentric(minimum: DefaultConstant.concentricRadius), isUniform: true)
            .fill(.white)
            .glass()
    }

    private var feedbackBackground: some View {
        LinearGradient(
            colors: Constant.feedbackGradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
