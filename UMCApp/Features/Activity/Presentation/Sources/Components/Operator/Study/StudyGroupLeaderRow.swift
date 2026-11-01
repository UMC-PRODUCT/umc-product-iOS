//
//  StudyGroupLeaderRow.swift
//  ActivityPresentation
//
//  Created by jaewon Lee on 7/15/26.
//

import ActivityDomain
import CoreDesignSystem
import CoreUIComponents
import SwiftUI

// MARK: - StudyGroupLeaderRow

/// 스터디 그룹 파트장 행
///
/// 프로필 이미지, 이름, 대학교, 역할 뱃지를 표시합니다.
struct StudyGroupLeaderRow: View, Equatable {

    // MARK: - Constants

    fileprivate enum Constants {
        static let avatarSize: CGFloat = 48
        static let rowPadding: CGFloat = 12
        static let surfaceCornerRadius: CGFloat = 16
    }

    // MARK: - Property

    /// 파트장 정보
    let leader: StudyGroupMember
    /// 스터디 파트 메인 색
    let partTintColor: Color

    // MARK: - Initializer

    /// - Parameters:
    ///   - leader: 표시할 파트장 정보
    ///   - partTintColor: 파트 메인 색상
    init(
        leader: StudyGroupMember,
        partTintColor: Color
    ) {
        self.leader = leader
        self.partTintColor = partTintColor
    }

    // MARK: - Equatable

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.leader == rhs.leader
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            avatarView

            // displayName = "{nickname}/{name}" 또는 "{name}". "운영이/김운영" 같은 단일 식별자가
            // 좁은 폭에서 임의로 줄바꿈되지 않도록 lineLimit(1) + minimumScaleFactor로 한 줄을
            // 강제하고, 그래도 부족하면 자동 축소 후 마지막에 ellipsis로 잘린다.
            Text(leader.displayName)
                .appFont(.callout, weight: .semibold, color: .black)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .truncationMode(.tail)
                .layoutPriority(1)

            InfoBadge(leader.university)
                .layoutPriority(-1)

            InfoBadge(leader.role.rawValue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Constants.rowPadding)
        .background(surfaceBackground)
    }

    // MARK: - View Components

    private var avatarView: some View {
        RemoteImage(
            urlString: leader.profileImageURL ?? "",
            size: CGSize(
                width: Constants.avatarSize,
                height: Constants.avatarSize
            ),
            cornerRadius: 0
        )
        .clipShape(Circle())
    }

    private var surfaceBackground: some View {
        RoundedRectangle(cornerRadius: Constants.surfaceCornerRadius)
            .fill(Color.Surface.content)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    VStack(spacing: DefaultSpacing.spacing16) {
        StudyGroupLeaderRow(
            leader: StudyGroupMember(
                serverID: "1",
                name: "김운영",
                nickname: "운영이",
                university: "홍익대학교",
                profileImageURL: nil,
                role: .leader
            ),
            partTintColor: .teal500
        )

        StudyGroupLeaderRow(
            leader: StudyGroupMember(
                serverID: "2",
                name: "이리더",
                university: "서울대학교",
                profileImageURL: nil,
                role: .leader
            ),
            partTintColor: .orange
        )
    }
    .padding()
}
#endif
