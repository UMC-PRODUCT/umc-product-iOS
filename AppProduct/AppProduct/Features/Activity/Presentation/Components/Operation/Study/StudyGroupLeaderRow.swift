//
//  StudyGroupLeaderRow.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/9/26.
//

import SwiftUI

// MARK: - StudyGroupLeaderRow

struct StudyGroupLeaderRow: View, Equatable {

    // MARK: - Constants

    fileprivate enum Constants {
        static let avatarSize: CGFloat = 48
        static let defaultAvatarIconSize: CGFloat = 20
        static let rowPadding: CGFloat = 8
    }

    // MARK: - Property

    let leader: StudyGroupMember

    // MARK: - Initializer

    init(leader: StudyGroupMember) {
        self.leader = leader
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
        .background(
            ConcentricRectangle(
                corners: .concentric(minimum: DefaultConstant.concentricRadius)
            )
            .fill(.gray.opacity(0.15))
        )
    }

    // MARK: - View Components

    private var avatarView: some View {
        Group {
            if let urlString = leader.profileImageURL, !urlString.isEmpty {
                RemoteImage(
                    urlString: urlString,
                    size: CGSize(
                        width: Constants.avatarSize,
                        height: Constants.avatarSize
                    ),
                    cornerRadius: 0,
                    placeholderImage: "person.fill"
                )
                .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: Constants.defaultAvatarIconSize))
                    .foregroundStyle(.white)
                    .frame(
                        width: Constants.avatarSize,
                        height: Constants.avatarSize
                    )
                    .background(.gray.opacity(0.4), in: Circle())
            }
        }
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
            )
        )

        StudyGroupLeaderRow(
            leader: StudyGroupMember(
                serverID: "2",
                name: "이리더",
                university: "서울대학교",
                profileImageURL: "https://example.com/avatar.jpg",
                role: .leader
            )
        )
    }
    .padding()
}
