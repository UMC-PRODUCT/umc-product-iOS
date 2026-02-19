//
//  StudyGroupLeaderRow.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/9/26.
//

import SwiftUI

// MARK: - StudyGroupLeaderRow

/// 스터디 그룹 파트장 행
///
/// 프로필 이미지, 이름, 대학교, 역할 뱃지를 표시합니다.
struct StudyGroupLeaderRow: View, Equatable {

    // MARK: - Constants

    fileprivate enum Constants {
        static let avatarSize: CGFloat = 48
        static let rowPadding: CGFloat = 8
        static let surfaceShadowRadius: CGFloat = 10
        static let surfaceHighlightRadius: CGFloat = 4
        static let surfaceShadowYOffset: CGFloat = 6
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
        HStack(spacing: DefaultSpacing.spacing16) {
            avatarView

            Text(leader.displayName)
                .appFont(.calloutEmphasis, color: .black)

            InfoBadge(leader.university)

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
            cornerRadius: 0,
            placeholderImage: "person.fill"
        )
        .clipShape(Circle())
    }

    private var surfaceBackground: some View {
        ConcentricRectangle(
            corners: .concentric(minimum: DefaultConstant.concentricRadius)
        )
        .fill(
            LinearGradient(
                colors: [
                    .white,
                    partTintColor.opacity(0.22),
                    partTintColor.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .glass()
        .shadow(
            color: .black.opacity(0.08),
            radius: Constants.surfaceShadowRadius,
            x: 0,
            y: Constants.surfaceShadowYOffset
        )
        .shadow(
            color: .white.opacity(0.7),
            radius: Constants.surfaceHighlightRadius,
            x: -2,
            y: -2
        )
    }
}

// MARK: - Preview

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
            partTintColor: .indigo500
        )

        StudyGroupLeaderRow(
            leader: StudyGroupMember(
                serverID: "2",
                name: "이리더",
                university: "서울대학교",
                profileImageURL: "https://example.com/avatar.jpg",
                role: .leader
            ),
            partTintColor: .orange
        )
    }
    .padding()
}
