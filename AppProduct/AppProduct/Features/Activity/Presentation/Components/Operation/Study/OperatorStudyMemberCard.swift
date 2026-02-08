//
//  OperatorStudyMemberCard.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/8/26.
//

import SwiftUI

/// 운영진 스터디 출석 관리 - 스터디원 카드
///
/// 스터디원 정보를 표시합니다.
///
/// ## 구성 요소
/// - 프로필 이미지 (원형)
/// - 이름(닉네임) + 파트 배지
/// - 학교 | 스터디 주제
/// - 수동 출석 버튼
///
/// ## 사용 예시
/// ```swift
/// OperatorStudyMemberCard(member: member) {
///     viewModel.manualAttendance(member)
/// }
/// ```
struct OperatorStudyMemberCard: View, Equatable {

    // MARK: - Constants

    fileprivate enum Constants {
        /// 아바타 이미지 크기
        static let avatarSize: CGFloat = 48
        /// 기본 아바타 아이콘 크기
        static let defaultAvatarIconSize: CGFloat = 20
        /// 수동 출석 버튼 아이콘 크기
        static let manualAttendanceIconSize: CGFloat = 24
        /// 파트 배지 배경 불투명도
        static let badgeBackgroundOpacity: CGFloat = 0.15
    }

    // MARK: - Property

    private let member: StudyMemberItem
    private var onManualAttendance: (() -> Void)?

    // MARK: - Initializer

    init(
        member: StudyMemberItem,
        onManualAttendance: (() -> Void)? = nil
    ) {
        self.member = member
        self.onManualAttendance = onManualAttendance
    }

    // MARK: - Equatable

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.member == rhs.member
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: DefaultSpacing.spacing16) {
            avatarView
            memberInfoSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DefaultConstant.defaultListPadding)
        .background(
            ConcentricRectangle(
                corners: .concentric(minimum: DefaultConstant.concentricRadius))
                .fill(.white)
                .glass()
        )
    }

    // MARK: - View Components

    private var avatarView: some View {
        Group {
            if let urlString = member.profileImageURL {
                RemoteImage(
                    urlString: urlString,
                    size: CGSize(width: Constants.avatarSize, height: Constants.avatarSize),
                    cornerRadius: 0,
                    placeholderImage: "person.fill"
                )
                .clipShape(Circle())
            } else {
                defaultAvatarImage
            }
        }
    }

    private var defaultAvatarImage: some View {
        Image(systemName: "person.fill")
            .font(.system(size: Constants.defaultAvatarIconSize))
            .foregroundStyle(.grey400)
            .frame(width: Constants.avatarSize, height: Constants.avatarSize)
            .background(Color.grey200, in: Circle())
    }

    private var memberInfoSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            memberNameRow
            memberDetailRow
        }
    }

    private var memberNameRow: some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            Text(member.displayName)
                .appFont(.calloutEmphasis)

            infoBadge(member.university)
            infoBadge(member.part.rawValue)

            if member.isBestWorkbook {
                trophyBadge
            }
        }
    }

    private var trophyBadge: some View {
        Image(systemName: "trophy.fill")
            .font(.app(.footnote))
            .foregroundStyle(.orange)
            .padding(DefaultConstant.iconPadding)
            .glassEffect(
                .regular.tint(
                    .orange.opacity(Constants.badgeBackgroundOpacity)
                )
            )
    }

    private func infoBadge(_ text: String) -> some View {
        Text(text)
            .appFont(.footnote, color: .grey600)
            .lineLimit(1)
            .padding(DefaultConstant.iconPadding)
            .glassEffect(
                .regular.tint(
                    .gray.opacity(Constants.badgeBackgroundOpacity)
                )
            )
    }

    private var memberDetailRow: some View {
        Text(member.studyTopic)
            .appFont(.subheadline, color: .indigo500)
            .lineLimit(1)
    }
}

// MARK: - Preview

#if DEBUG
#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: DefaultSpacing.spacing12) {
        OperatorStudyMemberCard(
            member: StudyMemberItem(
                serverID: "1",
                name: "홍길동",
                nickname: "닉네임",
                part: .ios,
                university: "중앙대",
                studyTopic: "SwiftUI 클론 코딩",
                profileImageURL: nil
            )
        ) {
            print("수동 출석")
        }

        OperatorStudyMemberCard(
            member: StudyMemberItem(
                serverID: "2",
                name: "김철수",
                nickname: "철수",
                part: .android,
                university: "서울대",
                studyTopic: "Jetpack Compose",
                profileImageURL: "https://picsum.photos/100"
            )
        )

        OperatorStudyMemberCard(
            member: StudyMemberItem(
                serverID: "3",
                name: "이영희",
                nickname: "영희",
                part: .spring,
                university: "한양대",
                studyTopic: "백엔드 아키텍처"
            )
        )
    }
    .padding()
}
#endif
