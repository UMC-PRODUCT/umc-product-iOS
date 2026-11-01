//
//  StudyGroupMemberChip.swift
//  ActivityPresentation
//
//  Created by jaewon Lee on 7/15/26.
//

import ActivityDomain
import CoreDesignSystem
import CoreUIComponents
import SwiftUI

/// 스터디 그룹 멤버 칩
///
/// 프로필 아바타와 이름을 표시하는 컴팩트 뷰입니다.
struct StudyGroupMemberChip: View, Equatable {
    // MARK: - Constants
    fileprivate enum Constants {
        static let avatarSize: CGFloat = 22
        static let avatarCornerRadius: CGFloat = 0
        static let bestBorderWidth: CGFloat = 1
        static let bestPointThreshold: Int = 0
        static let chipCornerRadius: CGFloat = 16
        static let chipHeight: CGFloat = 68
        static let chipHorizontalPadding: CGFloat = 6
        static let chipVerticalPadding: CGFloat = 6
        static let bestIconSize: CGFloat = 12
        static let bestIconContainerSize: CGFloat = 22
        static let bestIconOverlapOffset: CGFloat = 7
        static let bestIconSystemName: String = "trophy.fill"
        static let bestBorderOpacity: CGFloat = 0.32
        static let defaultBorderOpacity: CGFloat = 0.06
        static let bestIconBackgroundOpacity: CGFloat = 0.12
        static let chipWidth: CGFloat = 68
    }

    // MARK: - Property
    @ScaledMetric(relativeTo: .caption) private var chipWidth = Constants.chipWidth

    /// 표시할 멤버 정보
    let member: StudyGroupMember
    /// 베스트 워크북 배지 노출 여부
    let showsBestWorkbookBadge: Bool

    // MARK: - Initializer
    /// - Parameters:
    ///   - member: 표시할 멤버 정보
    ///   - showsBestWorkbookBadge: 베스트 워크북 배지 노출 여부
    init(
        member: StudyGroupMember,
        showsBestWorkbookBadge: Bool = false
    ) {
        self.member = member
        self.showsBestWorkbookBadge = showsBestWorkbookBadge
    }

    // MARK: - Equatable
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.member == rhs.member &&
            lhs.showsBestWorkbookBadge == rhs.showsBestWorkbookBadge
    }

    private var hasBestWorkbookPoint: Bool {
        showsBestWorkbookBadge && member.bestWorkbookPoint > Constants.bestPointThreshold
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: DefaultSpacing.spacing4) {
            avatarView
            // 칩에는 닉네임만 노출(없으면 본명). LeaderRow의 "닉네임/이름" 풀 표기와 다르게,
            // 좁은 폭의 칩에서는 한 글자라도 더 보여야 가독성이 높다는 디자인 결정.
            Text(member.nickname ?? member.name)
                .appFont(.caption1)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Constants.chipHorizontalPadding)
        .padding(.vertical, Constants.chipVerticalPadding)
        .frame(width: chipWidth)
        .frame(minHeight: Constants.chipHeight)
        .background(surfaceBackground)
        .overlay {
            RoundedRectangle(cornerRadius: Constants.chipCornerRadius)
                .stroke(
                    hasBestWorkbookPoint
                        ? .orange.opacity(Constants.bestBorderOpacity)
                        : .black.opacity(Constants.defaultBorderOpacity),
                    lineWidth: Constants.bestBorderWidth
                )
        }
        .overlay(alignment: .topTrailing) {
            if hasBestWorkbookPoint {
                bestWorkbookIcon
                    .offset(
                        x: Constants.bestIconOverlapOffset,
                        y: -Constants.bestIconOverlapOffset
                    )
            }
        }
    }

    // MARK: - View Components
    @ViewBuilder
    private var avatarView: some View {
        RemoteImage(
            urlString: member.profileImageURL ?? "",
            size: CGSize(
                width: Constants.avatarSize,
                height: Constants.avatarSize
            ),
            cornerRadius: Constants.avatarCornerRadius
        )
        .clipShape(Circle())
    }

    private var surfaceBackground: some View {
        RoundedRectangle(cornerRadius: Constants.chipCornerRadius)
            .fill(Color.Surface.content)
    }

    private var bestWorkbookIcon: some View {
        Image(systemName: Constants.bestIconSystemName)
            .font(.system(size: Constants.bestIconSize, weight: .semibold))
            .foregroundStyle(.orange)
            .frame(
                width: Constants.bestIconContainerSize,
                height: Constants.bestIconContainerSize
            )
            .background(.orange.opacity(Constants.bestIconBackgroundOpacity), in: Circle())
    }
}

// MARK: - Preview

#if DEBUG
#Preview("StudyGroupMemberChip") {
    HStack(spacing: DefaultSpacing.spacing8) {
        StudyGroupMemberChip(
            member: StudyGroupMember(
                serverID: "1",
                name: "김철수",
                nickname: "철수",
                university: "서울대",
                profileImageURL: nil,
                role: .leader
            )
        )
        StudyGroupMemberChip(
            member: StudyGroupMember(
                serverID: "2",
                name: "이영희",
                nickname: "영희",
                university: "연세대",
                profileImageURL: nil,
                role: .member,
                bestWorkbookPoint: 30
            ),
            showsBestWorkbookBadge: true
        )
    }
    .padding()
}
#endif
