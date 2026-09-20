//
//  AppleIntelligenceIntroSheet.swift
//  HomePresentation
//
//  Created by euijjang97 on 9/19/26.
//

import CoreDesignSystem
import FoundationModels
import SwiftUI
import UIKit

// MARK: - Constants

fileprivate enum Constants {
    static let navigationTitle = "AI 기능 안내"
    static let engineLabel = "Apple Intelligence"
    static let title = "Apple Intelligence 를 켜면\nAI 기능을 쓸 수 있어요"
    static let settingsTitle = "켜는 방법"
    static let settingsPath = "설정 > Apple Intelligence 및 Siri"
    static let openSettingsTitle = "설정 열기"
    static let settingsFallbackTitle = "설정으로 이동할 수 없어요"
    static let settingsHint = "켜고 나면 모델을 내려받는 동안 잠시 기다려야 할 수 있어요."
    static let dismissLabel = "닫기"

    static let engineImage = "apple.intelligence"
    static let settingsImage = "gearshape"

    static let heroIconSize: CGFloat = 72
    static let heroFrameSize: CGFloat = 128
    static let glowSize: CGFloat = 88
    static let glowBlurRadius: CGFloat = 24
    static let glowOpacity: Double = 0.45
    static let glowRotationDuration: TimeInterval = 8
    static let revealStartScale: CGFloat = 0.5
    static let revealBlurRadius: CGFloat = 12
    static let revealStartAngle: Double = -90
    static let revealDelay: TimeInterval = 0.35
    static let revealDuration: TimeInterval = 0.8
    static let revealBounce: Double = 0.4

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
/// Apple Intelligence 설정 URL을 지원하지 않는 OS에서는 기존 설정 경로를 다시 안내한다.
struct AppleIntelligenceIntroSheet: View {

    // MARK: - Property

    @Environment(\.dismiss) private var dismiss
    @State private var showsSettingsFallback = false

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
        .alert(Constants.settingsFallbackTitle, isPresented: $showsSettingsFallback) {
            Button(Constants.dismissLabel, role: .cancel) {}
        } message: {
            Text(Constants.settingsPath)
        }
    }

    // MARK: - View Component

    private var header: some View {
        VStack(spacing: DefaultSpacing.spacing12) {
            HeroSymbol()

            Text(Constants.engineLabel)
                .appFont(.callout, weight: .semibold, color: .grey700)

            Text(Constants.title)
                .appFont(.title2, weight: .semibold, color: .grey900)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
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

            Button(Constants.openSettingsTitle, action: openSettings)
                .buttonStyle(.glassProminent)

            Text(Constants.settingsHint)
                .appFont(.footnote, color: .grey500)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Constants.cardPadding)
        .glassEffect(
            .regular,
            in: .rect(corners: .concentric(minimum: DefaultConstant.concentricRadius))
        )
    }

    private func openSettings() {
        guard let url = URL(string: "App-prefs:root=APPLE_INTELLIGENCE") else {
            showsSettingsFallback = true
            return
        }

        Task { @MainActor in
            guard await UIApplication.shared.open(url) else {
                showsSettingsFallback = true
                return
            }
        }
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

// MARK: - HeroSymbol

/// 시트 상단의 `apple.intelligence` 히어로 심볼. 회전하며 튀어 오르듯 등장한 뒤,
/// 뒤편 글로우가 천천히 돌고 심볼은 숨 쉬듯 반복한다.
private struct HeroSymbol: View {

    // MARK: - Property

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isRevealed = false
    @State private var isAmbient = false

    // MARK: - Body

    var body: some View {
        ZStack {
            glow

            // apple.intelligence 는 Draw 주석이 없어 drawOn 이 효과가 없다 — 등장은 아래 스프링이 맡는다.
            // breathe 기본값은 불투명도도 흔들어 그라디언트가 바래 보여 plain(스케일만)을 쓴다.
            Image(systemName: Constants.engineImage)
                .font(.system(size: Constants.heroIconSize, weight: .medium))
                .foregroundStyle(.appleIntelligence)
                .symbolEffect(.breathe.plain, isActive: isAmbient)
        }
        .frame(width: Constants.heroFrameSize, height: Constants.heroFrameSize)
        .scaleEffect(isRevealed ? 1 : Constants.revealStartScale)
        .rotationEffect(.degrees(isRevealed ? 0 : Constants.revealStartAngle))
        .blur(radius: isRevealed ? 0 : Constants.revealBlurRadius)
        .opacity(isRevealed ? 1 : 0)
        .accessibilityHidden(true)
        .onAppear(perform: reveal)
    }

    // MARK: - View Component

    private var glow: some View {
        Circle()
            .fill(.appleIntelligence)
            .frame(width: Constants.glowSize, height: Constants.glowSize)
            .animation(
                .linear(duration: Constants.glowRotationDuration)
                    .repeatForever(autoreverses: false)
            ) {
                $0.rotationEffect(.degrees(isAmbient ? 360 : 0))
            }
            .blur(radius: Constants.glowBlurRadius)
            .opacity(Constants.glowOpacity)
    }

    // MARK: - Function

    private func reveal() {
        guard !reduceMotion else {
            isRevealed = true
            return
        }

        // 시트가 올라오는 동안 등장이 끝나 버리지 않게 잠시 늦춘다.
        withAnimation(
            .spring(duration: Constants.revealDuration, bounce: Constants.revealBounce)
                .delay(Constants.revealDelay)
        ) {
            isRevealed = true
        } completion: {
            isAmbient = true
        }
    }
}

// MARK: - Preview

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            AppleIntelligenceIntroSheet()
        }
}
