//
//  StudyGroupMemberChip.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/9/26.
//

import SwiftUI

/// 스터디 그룹 멤버 칩
///
/// 프로필 아바타와 이름을 표시하는 컴팩트 뷰입니다.
struct StudyGroupMemberChip: View, Equatable {
    // MARK: - Constants
    fileprivate enum Constants {
        static let avatarSize: CGFloat = 28
        static let bestBorderWidth: CGFloat = 1
        static let bestBadgeHorizontalPadding: CGFloat = 6
        static let bestBadgeVerticalPadding: CGFloat = 2
        static let chipWidth: CGFloat = 104
    }

    // MARK: - Property
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
        showsBestWorkbookBadge && member.bestWorkbookPoint > 0
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: DefaultSpacing.spacing8) {
            avatarView
            Text(member.name)
                .appFont(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if hasBestWorkbookPoint {
                bestWorkbookBadge
            }
        }
        .padding(DefaultConstant.badgePadding)
        .frame(width: Constants.chipWidth)
        .glassEffect(
            hasBestWorkbookPoint
                ? .regular.tint(.orange.opacity(0.22))
                : .regular.tint(.gray.opacity(0.15)),
            in: .rect(corners: .concentric(minimum: 16))
        )
        .overlay {
            if hasBestWorkbookPoint {
                ConcentricRectangle(corners: .concentric(minimum: 16))
                    .stroke(.orange.opacity(0.45), lineWidth: Constants.bestBorderWidth)
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
            cornerRadius: 0,
            placeholderImage: "person.fill"
        )
        .clipShape(Circle())
    }

    private var bestWorkbookBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "trophy.fill")
                .font(.caption2)
            Text("+\(member.bestWorkbookPoint)P")
                .appFont(.caption2Emphasis, color: .orange)
        }
        .foregroundStyle(.orange)
        .padding(.horizontal, Constants.bestBadgeHorizontalPadding)
        .padding(.vertical, Constants.bestBadgeVerticalPadding)
        .background(.orange.opacity(0.15), in: Capsule())
    }
}

// MARK: - Preview
#Preview("StudyGroupMemberChip") {
    VStack(spacing: DefaultSpacing.spacing16) {
        // With profile image
        HStack(spacing: DefaultSpacing.spacing8) {
            StudyGroupMemberChip(
                member: StudyGroupMember(
                    serverID: "1",
                    name: "김철수",
                    university: "서울대",
                    profileImageURL: "https://picsum.photos/200",
                    role: .leader
                )
            )
            StudyGroupMemberChip(
                member: StudyGroupMember(
                    serverID: "2",
                    name: "이영희",
                    university: "연세대",
                    profileImageURL: "https://picsum.photos/201",
                    role: .member,
                    bestWorkbookPoint: 30
                )
            )
            StudyGroupMemberChip(
                member: StudyGroupMember(
                    serverID: "3",
                    name: "박민수",
                    university: "고려대",
                    profileImageURL: "https://picsum.photos/202",
                    role: .member
                )
            )
        }

        // Without profile images
        HStack(spacing: DefaultSpacing.spacing8) {
            StudyGroupMemberChip(
                member: StudyGroupMember(
                    serverID: "4",
                    name: "최지훈",
                    university: "서울대",
                    profileImageURL: nil,
                    role: .leader
                )
            )
            StudyGroupMemberChip(
                member: StudyGroupMember(
                    serverID: "5",
                    name: "정서연",
                    university: "연세대",
                    profileImageURL: nil,
                    role: .member
                )
            )
            StudyGroupMemberChip(
                member: StudyGroupMember(
                    serverID: "6",
                    name: "강태영",
                    university: "고려대",
                    profileImageURL: nil,
                    role: .member
                )
            )
        }
    }
    .padding()
}
