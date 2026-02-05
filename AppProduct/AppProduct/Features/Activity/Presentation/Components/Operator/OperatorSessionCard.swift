//
//  OperatorSessionCard.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/5/26.
//

import SwiftUI

/// 운영진 출석 관리 화면 세션 카드
///
/// 세션 정보와 출석 통계를 표시하며, 펼침 상태에서 승인 대기 명단을 보여줍니다.
struct OperatorSessionCard: View, Equatable {

    // MARK: - Property

    private let session: Session
    private let isExpanded: Bool
    private let attendanceRate: Double
    private let attendedCount: Int
    private let totalCount: Int
    private let pendingCount: Int
    private let pendingMembers: [PendingMember]
    private let onTap: () -> Void
    private let onLocationTap: () -> Void
    private let onPendingListTap: () -> Void

    private var info: SessionInfo {
        session.info
    }

    // MARK: - Initializer

    init(
        session: Session,
        isExpanded: Bool = false,
        attendanceRate: Double = 0.0,
        attendedCount: Int = 0,
        totalCount: Int = 0,
        pendingCount: Int = 0,
        pendingMembers: [PendingMember] = [],
        onTap: @escaping () -> Void = {},
        onLocationTap: @escaping () -> Void = {},
        onPendingListTap: @escaping () -> Void = {}
    ) {
        self.session = session
        self.isExpanded = isExpanded
        self.attendanceRate = attendanceRate
        self.attendedCount = attendedCount
        self.totalCount = totalCount
        self.pendingCount = pendingCount
        self.pendingMembers = pendingMembers
        self.onTap = onTap
        self.onLocationTap = onLocationTap
        self.onPendingListTap = onPendingListTap
    }

    // MARK: - Equatable

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.session.id == rhs.session.id
        && lhs.isExpanded == rhs.isExpanded
        && lhs.attendanceRate == rhs.attendanceRate
        && lhs.attendedCount == rhs.attendedCount
        && lhs.totalCount == rhs.totalCount
        && lhs.pendingCount == rhs.pendingCount
        && lhs.pendingMembers.count == rhs.pendingMembers.count
    }
    
    // MARK: - Constant

    fileprivate enum Constants {
        static let iconSize: CGFloat = 64
        static let titleLineLimit: Int = 2
        static let statusRadius: CGFloat = 8
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            headerSection

            dateTimeSection

            AttendanceStatsRow(
                attendanceRate: attendanceRate,
                attendedCount: attendedCount,
                totalCount: totalCount,
                pendingCount: pendingCount
            )
            .equatable()

            if pendingCount > 0 {
                pendingSection
            } else {
                completionSection
            }
        }
        .padding(DefaultConstant.defaultCardPadding)
        .background {
            ConcentricRectangle(
                corners: .concentric(minimum: DefaultConstant.concentricRadius),
                isUniform: true
            )
            .fill(.white)
            .glass()
        }
    }

    // MARK: - Function

    /// 헤더 섹션 (아이콘, 제목, 상태, 위치 버튼)
    private var headerSection: some View {
        HStack(alignment: .center, spacing: DefaultSpacing.spacing16) {
            CardIconImage(
                image: info.category.symbol,
                color: info.category.color,
                isLoading: .constant(false)
            )
            .frame(width: Constants.iconSize, height: Constants.iconSize)

            VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                Text(info.title)
                    .appFont(.calloutEmphasis, color: .black)
                    .lineLimit(Constants.titleLineLimit)

                status
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onLocationTap) {
                Image(systemName: "location")
                    .font(.system(size: 16))
                    .foregroundStyle(.grey600)
                    .frame(width: 44, height: 44)
                    .background(Color.grey100, in: Circle())
            }
            .glassEffect(.regular)
        }
    }

    /// 날짜 및 시간 섹션
    private var dateTimeSection: some View {
        HStack(spacing: DefaultSpacing.spacing16) {
            HStack(spacing: DefaultSpacing.spacing4) {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundStyle(.grey500)

                Text(formattedDate)
                    .appFont(.subheadline, color: .grey600)
            }

            HStack(spacing: DefaultSpacing.spacing4) {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                    .foregroundStyle(.grey500)

                Text(formattedTime)
                    .appFont(.subheadline, color: .grey600)
            }
        }
    }

    /// 승인 대기 섹션 (탭 가능, 펼침/접힘)
    private var pendingSection: some View {
        VStack(spacing: 0) {
            Button(action: onPendingListTap) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(.orange)

                    Text("승인 대기 명단 확인하기")
                        .appFont(.calloutEmphasis, color: .orange)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.orange)
                }
                .padding(DefaultConstant.defaultListPadding)
                .background(
                    Color.orange100,
                    in: .rect(corners: .concentric(minimum: DefaultConstant.concentricRadius)))
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: DefaultSpacing.spacing8) {
                    ForEach(pendingMembers) { member in
                        PendingMemberRow(member: member)
                    }
                }
                .padding(.top, DefaultSpacing.spacing8)
            }
        }
    }

    /// 승인 완료 섹션
    private var completionSection: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title2)

            Text("모든 출석 승인이 완료되었습니다.")
                .appFont(.calloutEmphasis, color: .green)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(DefaultConstant.defaultListPadding)
        .background(
            .green.opacity(0.15),
            in: .rect(corners: .concentric(minimum: DefaultConstant.concentricRadius)))
    }

    /// 상태 칩 (진행 중, 출결일, 예정)
    @ViewBuilder
    private var status: some View {
        let (title) = sessionStatus
        
        Text(title)
            .appFont(.footnote, color: .green700)
    }

    /// 세션 상태 계산 (진행 중, 출결일, 예정)
    private var sessionStatus: (String) {
        let now = Date()

        if now < info.startTime {
            return ("진행전")
        } else if now >= info.startTime && now <= info.endTime {
            return ("진행중")
        } else {
            return ("종료됨")
        }
    }

    /// 날짜 포맷팅 (예: 2024.03.23 (토))
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd (E)"
        return formatter.string(from: info.startTime)
    }

    /// 시간 포맷팅 (예: 14:00 - 18:00)
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let start = formatter.string(from: info.startTime)
        let end = formatter.string(from: info.endTime)
        return "\(start) - \(end)"
    }
}

// MARK: - PendingMember Model

struct PendingMember: Identifiable, Equatable {
    let id: UUID
    let name: String
    let profileImage: String?
    let submittedAt: Date
}

// MARK: - PendingMemberRow

private struct PendingMemberRow: View {
    let member: PendingMember

    var body: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            Circle()
                .fill(Color.grey300)
                .frame(width: 36, height: 36)
                .overlay {
                    Text(member.name.prefix(1))
                        .appFont(.bodyEmphasis, color: .grey600)
                }

            VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                Text(member.name)
                    .appFont(.calloutEmphasis)

                Text(timeAgo(from: member.submittedAt))
                    .appFont(.footnote, color: .grey500)
            }

            Spacer()

            HStack(spacing: DefaultSpacing.spacing8) {
                Button {
                    // 승인 액션
                } label: {
                    Text("승인")
                        .appFont(.caption1Emphasis, color: .white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green500, in: Capsule())
                }

                Button {
                    // 거부 액션
                } label: {
                    Text("거부")
                        .appFont(.caption1Emphasis, color: .grey600)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.grey200, in: Capsule())
                }
            }
            .buttonStyle(.plain)
        }
        .padding(DefaultConstant.defaultListPadding)
        .background(.white, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.grey200, lineWidth: 1)
        )
    }

    private func timeAgo(from date: Date) -> String {
        let interval = Date.now.timeIntervalSince(date)
        let minutes = Int(interval / 60)

        if minutes < 1 {
            return "방금 전"
        } else if minutes < 60 {
            return "\(minutes)분 전"
        } else {
            let hours = minutes / 60
            return "\(hours)시간 전"
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // 진행 중 - 승인 대기 있음 (접힘)
            OperatorSessionCard(
                session: AttendancePreviewData.sessions[1],
                isExpanded: false,
                attendanceRate: 0.85,
                attendedCount: 34,
                totalCount: 40,
                pendingCount: 3,
                pendingMembers: mockPendingMembers
            )

            // 출결일 - 모두 승인 완료
            OperatorSessionCard(
                session: AttendancePreviewData.sessions[0],
                isExpanded: false,
                attendanceRate: 0.85,
                attendedCount: 34,
                totalCount: 40,
                pendingCount: 0,
                pendingMembers: []
            )

            // 진행 중 - 펼침 (승인 대기 명단)
            OperatorSessionCard(
                session: AttendancePreviewData.sessions[1],
                isExpanded: true,
                attendanceRate: 0.85,
                attendedCount: 34,
                totalCount: 40,
                pendingCount: 3,
                pendingMembers: mockPendingMembers
            )
        }
        .padding()
    }
    .background(Color.grey100)
}

private let mockPendingMembers: [PendingMember] = [
    PendingMember(
        id: UUID(),
        name: "김철수",
        profileImage: nil,
        submittedAt: Date.now.addingTimeInterval(-120)
    ),
    PendingMember(
        id: UUID(),
        name: "이영희",
        profileImage: nil,
        submittedAt: Date.now.addingTimeInterval(-300)
    ),
    PendingMember(
        id: UUID(),
        name: "박민수",
        profileImage: nil,
        submittedAt: Date.now.addingTimeInterval(-600)
    )
]
