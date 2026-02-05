//
//  AttendanceStatsRow.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/5/26.
//

import SwiftUI

/// 운영진 세션 카드 출석 통계 행
///
/// 출석률, 출석 인원, 승인 대기 수를 가로로 표시합니다.
struct AttendanceStatsRow: View, Equatable {

    // MARK: - Property

    /// 출석률 (0.0~1.0)
    let attendanceRate: Double

    /// 출석 인원
    let attendedCount: Int

    /// 전체 인원
    let totalCount: Int

    /// 승인 대기 수
    let pendingCount: Int

    // MARK: - Equatable

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.attendanceRate == rhs.attendanceRate
        && lhs.attendedCount == rhs.attendedCount
        && lhs.totalCount == rhs.totalCount
        && lhs.pendingCount == rhs.pendingCount
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            StatCard(
                label: "출석률",
                value: "\(Int(attendanceRate * 100))%",
                color: .indigo
            )

            StatCard(
                label: "출석 인원",
                value: "\(attendedCount)/\(totalCount)",
                color: .green
            )

            StatCard(
                label: "승인 대기",
                value: "\(pendingCount)명",
                color: .orange
            )
        }
    }
}

// MARK: - StatCard

private struct StatCard: View {
    let label: String
    let value: String
    let color: StatCardColor
    
    private enum Constants {
        static let cardPadding: CGFloat = 12
    }

    var body: some View {
        VStack(spacing: DefaultSpacing.spacing4) {
            Text(label)
                .appFont(.caption1, color: color.labelColor)

            Text(value)
                .appFont(.calloutEmphasis, color: color.valueColor)
        }
        .frame(maxWidth: .infinity)
        .padding(Constants.cardPadding)
        .background(
            color.backgroundColor,
            in: .rect(corners: .concentric(minimum: DefaultConstant.concentricRadius)))
    }
}

// MARK: - StatCardColor

private enum StatCardColor {
    case indigo
    case green
    case orange

    var backgroundColor: Color {
        switch self {
        case .indigo: return Color.indigo100
        case .green: return Color.green100
        case .orange: return Color.orange100
        }
    }

    var labelColor: Color {
        switch self {
        case .indigo: return Color.indigo500
        case .green: return Color.green700
        case .orange: return Color.orange600
        }
    }

    var valueColor: Color {
        switch self {
        case .indigo: return Color.indigo500
        case .green: return Color.green700
        case .orange: return Color.orange600
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ZStack {
        Color.grey100.frame(height: 300)

        AttendanceStatsRow(
            attendanceRate: 0.85,
            attendedCount: 34,
            totalCount: 40,
            pendingCount: 3
        )
        .padding()
    }
}
