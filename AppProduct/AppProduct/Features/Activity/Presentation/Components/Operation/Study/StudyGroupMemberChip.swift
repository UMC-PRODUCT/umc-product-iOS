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
        static let avatarSize: CGFloat = 24
        static let bestBorderWidth: CGFloat = 1
        static let chipHeight: CGFloat = 82
        static let chipHorizontalPadding: CGFloat = 8
        static let chipVerticalPadding: CGFloat = 8
        static let bestIconSize: CGFloat = 10
        static let bestIconContainerSize: CGFloat = 18
        static let bestIconPadding: CGFloat = 5
        static let chipWidth: CGFloat = 90
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
        VStack(spacing: DefaultSpacing.spacing4) {
            avatarView
            Text(member.name)
                .appFont(.footnote)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, Constants.chipHorizontalPadding)
        .padding(.vertical, Constants.chipVerticalPadding)
        .frame(width: Constants.chipWidth, height: Constants.chipHeight)
        .glassEffect(
            .regular.tint(.gray.opacity(0.15)),
            in: .rect(corners: .concentric(minimum: 16))
        )
        .overlay {
            ConcentricRectangle(corners: .concentric(minimum: 16))
                .stroke(
                    hasBestWorkbookPoint
                        ? .orange.opacity(0.32)
                        : .black.opacity(0.06),
                    lineWidth: Constants.bestBorderWidth
                )
        }
        .overlay(alignment: .topTrailing) {
            if hasBestWorkbookPoint {
                bestWorkbookIcon
                    .padding(Constants.bestIconPadding)
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

    private var bestWorkbookIcon: some View {
        Image(systemName: "trophy.fill")
            .font(.system(size: Constants.bestIconSize, weight: .semibold))
        .foregroundStyle(.orange)
        .frame(
            width: Constants.bestIconContainerSize,
            height: Constants.bestIconContainerSize
        )
        .background(.orange.opacity(0.12), in: Circle())
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
