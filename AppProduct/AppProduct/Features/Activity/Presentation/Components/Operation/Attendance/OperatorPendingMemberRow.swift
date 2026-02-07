//
//  OperatorPendingMemberRow.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/5/26.
//

import SwiftUI

/// 운영진 출석 관리 승인 대기 멤버 행
///
/// 승인 대기 중인 멤버 정보와 승인/반려 버튼을 표시합니다.
struct OperatorPendingMemberRow: View, Equatable {

    // MARK: - Property

    private let member: OperatorPendingMember

    // MARK: - Initializer

    init(member: OperatorPendingMember) {
        self.member = member
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
    }

    // MARK: - View Components

    private var avatarView: some View {
        Image(systemName: "person.2.fill")
            .font(.system(size: 16))
            .foregroundStyle(.grey400)
            .frame(width: DefaultConstant.iconSize, height: DefaultConstant.iconSize)
            .background(Color.grey200, in: .circle)
    }

    private var memberInfoSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            Text(member.displayName)
                .appFont(.calloutEmphasis, color: .black)

            HStack(spacing: DefaultSpacing.spacing8) {
                Text(member.university)
                Text("\(formattedTime) 요청")
            }
            .appFont(.footnote, color: .grey600)
        }
    }

    // MARK: - Function

    /// 시간 포맷팅 (HH:mm)
    private var formattedTime: String {
        member.requestTime.toHourMinutes()
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 12) {
        // 사유 있음
        OperatorPendingMemberRow(
            member: OperatorPendingMember(
                serverID: "1",
                name: "홍길동",
                nickname: "닉네임",
                university: "중앙대학교",
                requestTime: Date.now.addingTimeInterval(-300),
                reason: "지각 사유입니다"
            )
        )

        // 사유 없음
        OperatorPendingMemberRow(
            member: OperatorPendingMember(
                serverID: "2",
                name: "김철수",
                nickname: nil,
                university: "서울대학교",
                requestTime: Date.now.addingTimeInterval(-600),
                reason: nil
            )
        )
    }
    .padding()
    .background(Color.grey100)
}
