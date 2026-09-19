//
//  AppleIntelligenceIntroSheet.swift
//  HomePresentation
//
//  Created by euijjang97 on 9/19/26.
//

import CoreDesignSystem
import FoundationModels
import SwiftUI

// MARK: - Constants

fileprivate enum Constants {
    static let navigationTitle = "AI 기능 안내"
    static let engineLabel = "Apple Intelligence"
    static let title = "Apple Intelligence 를 켜면\nAI 기능을 쓸 수 있어요"
    static let settingsTitle = "켜는 방법"
    static let settingsPath = "설정 > Apple Intelligence 및 Siri"
    static let settingsHint = "켜고 나면 모델을 내려받는 동안 잠시 기다려야 할 수 있어요."
    static let dismissLabel = "닫기"

    static let engineImage = "apple.intelligence"
    static let settingsImage = "gearshape"

    static let headerIconSize: CGFloat = 16
    static let featureIconSize: CGFloat = 20
    static let featureIconFrame: CGFloat = 28
    static let cardPadding: EdgeInsets = .init(
        top: DefaultSpacing.spacing16,
        leading: DefaultConstant.defaultSafeHorizon,
        bottom: DefaultSpacing.spacing16,
        trailing: DefaultConstant.defaultSafeHorizon
    )

    static let features: [Feature] = [
        Feature(
            image: "megaphone",
            title: "공지 AI 요약 · 작성 개선",
            description: "긴 공지를 요약해 읽고, 작성 중인 공지를 다듬어요."
        ),
        Feature(
            image: "calendar.badge.plus",
            title: "일정 AI 자동 입력",
            description: "문장 한 줄로 일정의 제목 · 시간 · 장소를 채워요."
        ),
        Feature(
            image: "bubble.left.and.bubble.right",
            title: "스레드 요약 · 분류",
            description: "안 읽은 대화를 요약하고, 스레드 분류와 특징 다듬기를 도와요."
        )
    ]

    struct Feature {
        let image: String
        let title: String
        let description: String
    }
}

/// Apple Intelligence 가 꺼진 사용자에게 앱의 온디바이스 AI 기능과 켜는 방법을 알리는 시트.
///
/// AI 진입 버튼은 모델이 쓸 수 있을 때만 보이므로, 꺼 둔 사용자는 기능이 있다는 것조차
/// 알 수 없다. 홈 진입 시 한 번만 띄운다 (`HomeView`).
///
/// - Note: Apple Intelligence 설정 화면으로 바로 가는 공개 URL 이 없어 경로를 글로 안내한다.
///   `UIApplication.openSettingsURLString` 은 앱 설정으로만 이동한다.
struct AppleIntelligenceIntroSheet: View {

    // MARK: - Property

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DefaultSpacing.spacing24) {
                    header
                    featureCard
                    settingsCard
                }
                .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
                .padding(.vertical, DefaultSpacing.spacing24)
            }
            .umcDefaultBackground()
            .navigationTitle(Constants.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) { dismiss() }
                        .accessibilityLabel(Constants.dismissLabel)
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - View Component

    private var header: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing12) {
            HStack(spacing: DefaultSpacing.spacing8) {
                Image(systemName: Constants.engineImage)
                    .font(.system(size: Constants.headerIconSize, weight: .medium))
                    .foregroundStyle(.appleIntelligence)

                Text(Constants.engineLabel)
                    .appFont(.callout, weight: .semibold, color: .grey700)
            }
            .accessibilityElement(children: .combine)

            Text(Constants.title)
                .appFont(.title2, weight: .semibold, color: .grey900)
        }
    }

    private var featureCard: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            ForEach(Constants.features, id: \.title) { feature in
                featureRow(feature)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Constants.cardPadding)
        .glassEffect(
            .regular,
            in: .rect(corners: .concentric(minimum: DefaultConstant.concentricRadius))
        )
    }

    private func featureRow(_ feature: Constants.Feature) -> some View {
        HStack(alignment: .top, spacing: DefaultSpacing.spacing12) {
            Image(systemName: feature.image)
                .font(.system(size: Constants.featureIconSize))
                .foregroundStyle(Color.indigo500)
                .frame(width: Constants.featureIconFrame)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                Text(feature.title)
                    .appFont(.callout, weight: .semibold, color: .grey900)
                Text(feature.description)
                    .appFont(.subheadline, color: .grey600)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            Label(Constants.settingsTitle, systemImage: Constants.settingsImage)
                .appFont(.callout, weight: .semibold, color: .grey700)

            Text(Constants.settingsPath)
                .appFont(.body, weight: .semibold, color: .grey900)

            Text(Constants.settingsHint)
                .appFont(.footnote, color: .grey500)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Constants.cardPadding)
        .glassEffect(
            .regular,
            in: .rect(corners: .concentric(minimum: DefaultConstant.concentricRadius))
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Function

extension AppleIntelligenceIntroSheet {

    /// 안내 시트를 띄울지 판정한다.
    ///
    /// 설정만 켜면 쓸 수 있는 `.appleIntelligenceNotEnabled` 에서만 띄운다.
    /// `.modelNotReady` 는 곧 자동으로 켜지고, `.deviceNotEligible` 은 켤 방법이 없다.
    static func shouldPresent(
        availability: SystemLanguageModel.Availability,
        hasBeenShown: Bool
    ) -> Bool {
        guard !hasBeenShown,
              case .unavailable(.appleIntelligenceNotEnabled) = availability
        else { return false }
        return true
    }
}

// MARK: - Preview

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            AppleIntelligenceIntroSheet()
        }
}
