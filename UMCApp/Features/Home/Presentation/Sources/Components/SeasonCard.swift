//
//  SeasonCard.swift
//  HomePresentation
//
//  Created by euijjang97 on 7/9/26.
//

import CoreDesignSystem
import HomeDomain
import SwiftUI

/// 홈 화면 시즌 카드 — 소속 기수 목록 또는 누적 활동일을 표시한다.
///
/// 홈 스크롤/상태 갱신마다 재평가되지만 표시 값은 프로필 재조회 때만 바뀌므로,
/// `Equatable`로 불필요한 body 재계산을 걸러낸다 (호출부에서 `.equatable()` 적용).
struct SeasonCard: View, Equatable {

    // MARK: - Property

    let seasonType: SeasonType

    // MARK: - Constants

    fileprivate enum Constants {
        static let cardHeight: CGFloat = 120
        static let iconSize: CGFloat = 24
        static let mainPadding = EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
    }

    // MARK: - Body

    var body: some View {
        content
        .padding(Constants.mainPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: Constants.cardHeight)
        .background(
            Color.Surface.content,
            in: .rect(corners: .concentric(minimum: DefaultConstant.concentricRadius), isUniform: true)
        )
    }

    // MARK: - Component

    @ViewBuilder
    private var content: some View {
        if seasonType == .productAccount {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing12) {
                HStack(spacing: DefaultSpacing.spacing8) {
                    icon.accessibilityHidden(true)
                    Text("UMC PRODUCT")
                        .appFont(.callout, weight: .semibold, color: .grey900)
                }
                Text("프로덕트 전용 계정으로 이용 중입니다")
                    .appFont(.subheadline, color: .grey600)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
        } else {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
                icon
                Spacer(minLength: 0)
                title
                value
            }
        }
    }

    private var icon: some View {
        Image(systemName: iconName)
            .font(.system(size: Constants.iconSize))
            .foregroundStyle(Color.teal600)
    }

    private var title: some View {
        Text(titleText)
            .appFont(.caption1, weight: .semibold, color: .grey600)
    }

    @ViewBuilder
    private var value: some View {
        switch seasonType {
        case .productAccount:
            EmptyView()
        case .days(let count):
            Text("\(count)일")
                .appFont(.title3, weight: .semibold, color: .grey900)
        case .gens(let gens):
            Text(gens.map { "\($0)기" }.joined(separator: ", "))
                .appFont(.callout, weight: .semibold, color: .grey900)
                .lineLimit(2)
        }
    }

    private var iconName: String {
        switch seasonType {
        case .productAccount:
            "person.crop.rectangle"
        case .days:
            "flame.fill"
        case .gens:
            "person.2.fill"
        }
    }

    private var titleText: String {
        switch seasonType {
        case .productAccount:
            "UMC PRODUCT"
        case .days:
            "누적 활동일"
        case .gens:
            "소속 기수"
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview(traits: .sizeThatFitsLayout) {
    HStack(spacing: DefaultSpacing.spacing12) {
        SeasonCard(seasonType: .gens(["11", "12"]))
        SeasonCard(seasonType: .days(128))
    }
    .padding()
}
#endif
