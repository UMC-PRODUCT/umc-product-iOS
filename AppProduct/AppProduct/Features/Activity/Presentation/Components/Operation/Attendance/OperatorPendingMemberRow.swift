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

    var onReasonTap: (() -> Void)?
    var onRejectTap: () -> Void
    var onApproveTap: () -> Void

    // MARK: - Initializer

    init(
        member: OperatorPendingMember,
        onReasonTap: (() -> Void)? = nil,
        onRejectTap: @escaping () -> Void,
        onApproveTap: @escaping () -> Void
    ) {
        self.member = member
        self.onReasonTap = onReasonTap
        self.onRejectTap = onRejectTap
        self.onApproveTap = onApproveTap
    }

    // MARK: - Equatable

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.member == rhs.member
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: DefaultSpacing.spacing16) {
            // Avatar
            Image(systemName: "person.2.fill")
                .font(.system(size: 16))
                .foregroundStyle(.grey400)
                .frame(width: DefaultConstant.iconSize, height: DefaultConstant.iconSize)
                .background(Color.grey200, in: .circle)

            // 텍스트 영역
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                // 이름(닉네임)
                Text(member.displayName)
                    .appFont(.calloutEmphasis, color: .black)

                // 학교 + 시간
                Text("\(member.university) \(formattedTime) 요청")
                    .appFont(.subheadline, color: .grey600)
            }

            Spacer()

            // 버튼들
            HStack(spacing: DefaultSpacing.spacing8) {
                // 사유 확인 버튼 (reason이 있을 때만)
                if member.hasReason {
                    Button(action: { onReasonTap?() }) {
                        Image(systemName: "exclamationmark")
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 24, height: 24)
                            .foregroundStyle(.white)
                            .background(Color.orange500, in: Circle())
                    }
                }

                // 반려 버튼
                Button(action: onRejectTap) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.white)
                        .background(Color.red500, in: Circle())
                }

                // 승인 버튼
                Button(action: onApproveTap) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.green500)
                        .background(Color.green100, in: Circle())
                }
            }
            .buttonStyle(.plain)
        }
        .padding(DefaultConstant.defaultListPadding)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.grey200, lineWidth: 1)
        )
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
            ),
            onReasonTap: { print("사유 확인") },
            onRejectTap: { print("반려") },
            onApproveTap: { print("승인") }
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
            ),
            onReasonTap: nil,
            onRejectTap: { print("반려") },
            onApproveTap: { print("승인") }
        )
    }
    .padding()
    .background(Color.grey100)
}
