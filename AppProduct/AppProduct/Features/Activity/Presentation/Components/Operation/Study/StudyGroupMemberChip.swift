//
//  StudyGroupMemberChip.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/9/26.
//

import SwiftUI

struct StudyGroupMemberChip: View, Equatable {
    // MARK: - Constants
    fileprivate enum Constants {
        static let avatarSize: CGFloat = 28
        static let defaultIconSize: CGFloat = 12
    }

    // MARK: - Property
    let member: StudyGroupMember

    // MARK: - Initializer
    init(member: StudyGroupMember) {
        self.member = member
    }

    // MARK: - Equatable
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.member == rhs.member
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: DefaultSpacing.spacing8) {
            avatarView
            Text(member.name)
                .appFont(.subheadline)
        }
        .padding(DefaultConstant.badgePadding)
        .glassEffect(
            .regular.tint(.gray.opacity(0.15)),
            in: .rect(corners: .concentric(minimum: 16))
        )
    }

    // MARK: - View Components
    @ViewBuilder
    private var avatarView: some View {
        if let urlString = member.profileImageURL, !urlString.isEmpty {
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
                .font(.system(size: Constants.defaultIconSize))
                .foregroundStyle(.white)
                .frame(
                    width: Constants.avatarSize,
                    height: Constants.avatarSize
                )
                .background(Color.gray.opacity(0.4), in: Circle())
        }
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
                    role: .member
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
