//
//  MissionCardHeader.swift
//  AppProduct
//
//  Created by jaewon Lee on 01/29/26.
//

import SwiftUI

// MARK: - MissionCardHeader

/// 미션 카드 헤더 (주차 태그, 플랫폼 태그, 제목, 상태 뱃지, 펼치기 버튼)
struct MissionCardHeader: View {

    // MARK: - Property

    let model: MissionCardModel
    let isExpanded: Bool
    let onToggle: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: DefaultSpacing.spacing8) {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
                HStack(spacing: DefaultSpacing.spacing4) {
                    ChipButton("Week \(model.week)", isSelected: false)
                        .buttonSize(.small)

                    ChipButton(model.platform, isSelected: false)
                        .buttonSize(.small)
                }

                Text(model.title)
                    .font(.app(.title3, weight: .bold))
                    .foregroundStyle(
                        model.status == .inProgress ? Color.indigo500 : Color.grey900
                    )
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            StatusBadgePresenter(status: model.status)

            Button(action: onToggle) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.grey600)
            }
        }
    }
}

// MARK: - Constants

private enum StatusBadgeConstants {
    static let badgePadding: CGFloat = 8
    static let borderWidth: CGFloat = 1
}

// MARK: - StatusBadgePresenter

/// 상태 뱃지 표시
private struct StatusBadgePresenter: View, Equatable {

    // MARK: - Property

    let status: MissionStatus

    // MARK: - Body

    var body: some View {
        Text(status.displayText)
            .appFont(.caption1, weight: .bold, color: status.foregroundColor)
            .padding(DefaultConstant.badgePadding)
            .background(status.backgroundColor)
            .clipShape(.rect(corners: .concentric))
            .glassEffect(.clear, in: .rect(corners: .concentric))
            .overlay {
                if status.hasBorder {
                    ConcentricRectangle()
                        .stroke(Color.indigo500, lineWidth: StatusBadgeConstants.borderWidth)
                }
            }
    }
}

// MARK: - Preview

#Preview("MissionCardHeader") {
    VStack(spacing: 16) {
        MissionCardHeader(
            model: MissionCardModel(
                week: 1,
                platform: "iOS",
                title: "SwiftUI 기초 학습",
                missionTitle: "로그인 화면 구현하기",
                status: .notStarted
            ),
            isExpanded: false
        ) { }

        MissionCardHeader(
            model: MissionCardModel(
                week: 2,
                platform: "Android",
                title: "Kotlin 기초 학습",
                missionTitle: "회원가입 화면 구현하기",
                status: .inProgress
            ),
            isExpanded: true
        ) { }

        MissionCardHeader(
            model: MissionCardModel(
                week: 3,
                platform: "Web",
                title: "React 기초 학습",
                missionTitle: "메인 화면 구현하기",
                status: .pass
            ),
            isExpanded: false
        ) { }
    }
    .padding()
}
