//
//  AttendanceLiveActivityViews.swift
//  UMCAppWidget
//
//  Created by euijjang97 on 9/19/26.
//

import CoreDesignSystem
import CoreWidgetShared
import SwiftUI
import WidgetKit

// MARK: - Lock Screen

/// 잠금 화면·배너. 워치 Smart Stack(`.small`)에서는 점·타이머·단계 문구만 남긴다.
struct AttendanceLockScreenView: View {

    // MARK: - Property

    @Environment(\.activityFamily) private var activityFamily

    let attributes: AttendanceActivityAttributes
    let phase: AttendanceActivityPhase

    // MARK: - Body

    var body: some View {
        Group {
            switch activityFamily {
            case .small:
                smallContent
            default:
                lockScreenContent
            }
        }
        // 배경을 항상 검정으로 고정하므로, 시스템 진행 막대 트랙도 다크 톤으로 맞춘다.
        .environment(\.colorScheme, .dark)
    }

    private var lockScreenContent: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
                AttendanceActivityHeader(title: attributes.title, phase: phase)

                HStack(alignment: .firstTextBaseline, spacing: DefaultSpacing.spacing4) {
                    AttendanceCountdownText(attributes: attributes, phase: phase)
                        .font(.system(size: Constants.lockScreenTimerSize, weight: .bold))
                        .foregroundStyle(phase.timerColor)
                        .fixedSize()
                    AttendancePhaseText(phase: phase)
                }

                AttendancePhaseProgressBar(attributes: attributes, phase: phase)
            }
            .frame(maxWidth: Constants.lockScreenContentWidth, alignment: .leading)

            Spacer(minLength: 0)

            AttendancePhaseIcon(phase: phase, size: Constants.lockScreenIconSize)
                // 시안처럼 오른쪽 가장자리에서 살짝 잘려 보이게 밀어낸다.
                .offset(x: Constants.lockScreenIconOverhang)
        }
        .padding(DefaultSpacing.spacing16)
        .background { AttendancePhaseGlow(phase: phase) }
    }

    private var smallContent: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            HStack(spacing: DefaultSpacing.spacing4) {
                AttendancePhaseDot(phase: phase)
                AttendanceCountdownText(attributes: attributes, phase: phase)
                    .font(.system(size: Constants.smallTimerSize, weight: .bold))
                    .foregroundStyle(phase.timerColor)
            }
            AttendancePhaseText(phase: phase)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DefaultSpacing.spacing8)
    }
}

// MARK: - Dynamic Island Expanded

/// Dynamic Island 확장 하단 영역 — 큰 카운트다운·단계 문구·진행 막대와 오른쪽 아이콘.
struct AttendanceExpandedContent: View {

    // MARK: - Property

    let attributes: AttendanceActivityAttributes
    let phase: AttendanceActivityPhase

    // MARK: - Body

    var body: some View {
        HStack(alignment: .center, spacing: DefaultSpacing.spacing12) {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                AttendanceCountdownText(attributes: attributes, phase: phase)
                    .font(.system(size: Constants.expandedTimerSize, weight: .bold))
                    .foregroundStyle(phase.timerColor)
                AttendancePhaseText(phase: phase)
                AttendancePhaseProgressBar(attributes: attributes, phase: phase)
                    .padding(.top, DefaultSpacing.spacing4)
            }
            .frame(maxWidth: Constants.lockScreenContentWidth, alignment: .leading)

            Spacer(minLength: 0)

            AttendancePhaseIcon(phase: phase, size: Constants.expandedIconSize)
        }
        .environment(\.colorScheme, .dark)
    }
}

// MARK: - Components

/// 단계 색 둥근 사각 "U" 배지 + 세션 제목.
struct AttendanceActivityHeader: View {
    let title: String
    let phase: AttendanceActivityPhase

    var body: some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            Text("U")
                .appFont(.caption1, weight: .semibold, color: .white)
                .frame(width: Constants.badgeSize, height: Constants.badgeSize)
                .background(
                    phase.tint,
                    in: RoundedRectangle(cornerRadius: Constants.badgeCornerRadius)
                )
            Text(title)
                .appFont(.caption1, weight: .medium, color: .white)
                .lineLimit(1)
        }
    }
}

/// 단계별 카운트다운.
///
/// 정시·지각은 `timerInterval` 이라 앱이 깨어 있지 않아도 시스템이 초 단위로 줄여 그린다.
/// 마감은 더 셀 시간이 없으므로 "00:00" 을 고정으로 보여 준다.
struct AttendanceCountdownText: View {
    let attributes: AttendanceActivityAttributes
    let phase: AttendanceActivityPhase

    var body: some View {
        timerText.monospacedDigit()
    }

    private var timerText: Text {
        switch phase {
        case .beforeCheckIn:
            Text(attributes.checkInStartAt, style: .timer)
        case .onTime:
            Text(timerInterval: attributes.checkInStartAt...attributes.onTimeEndAt)
        case .late:
            Text(timerInterval: attributes.onTimeEndAt...attributes.lateEndAt)
        case .closed:
            Text(verbatim: "00:00")
        }
    }
}

/// 단계 문구 ("출석 가능" 등) — 단계 색 semibold.
struct AttendancePhaseText: View {
    let phase: AttendanceActivityPhase

    var body: some View {
        Text(phase.title)
            .appFont(.subheadline, weight: .semibold, color: phase.tint)
            .lineLimit(1)
    }
}

/// Dynamic Island compact·minimal 과 `.small` 에 쓰는 단계 색 점.
struct AttendancePhaseDot: View {
    let phase: AttendanceActivityPhase

    var body: some View {
        Circle()
            .fill(phase.tint)
            .frame(width: Constants.dotSize, height: Constants.dotSize)
    }
}

/// 단계 아이콘 — SF Symbol 을 단계 색 그라데이션으로 칠하고 같은 색으로 번지게 한다.
struct AttendancePhaseIcon: View {
    let phase: AttendanceActivityPhase
    let size: CGFloat

    var body: some View {
        Image(systemName: phase.symbolName)
            .symbolRenderingMode(.hierarchical)
            .font(.system(size: size))
            .foregroundStyle(phase.tint.gradient)
            .shadow(color: phase.tint.opacity(Constants.glowOpacity), radius: size / 4)
    }
}

/// 잠금 화면 배경 — 오른쪽 아래에서 번지는 단계 색 광원.
struct AttendancePhaseGlow: View {
    let phase: AttendanceActivityPhase

    var body: some View {
        RadialGradient(
            colors: [phase.tint.opacity(Constants.backgroundGlowOpacity), .clear],
            center: .bottomTrailing,
            startRadius: 0,
            endRadius: Constants.backgroundGlowRadius
        )
    }
}

/// [출석][지각][결석] 3분할 진행 막대.
///
/// 지난 구간은 가득, 현재 구간은 경과만큼, 앞으로 올 구간은 빈 트랙으로 그린다.
/// 세 구간 모두 같은 `ProgressView` 로 그려 트랙 모양을 맞춘다 — 현재 구간만 시스템이
/// 시간에 따라 채우는 `timerInterval` 버전이다.
struct AttendancePhaseProgressBar: View {
    let attributes: AttendanceActivityAttributes
    let phase: AttendanceActivityPhase

    var body: some View {
        HStack(alignment: .top, spacing: DefaultSpacing.spacing4) {
            segment(.onTime, label: "출석")
            segment(.late, label: "지각")
            segment(.closed, label: "결석")
        }
    }

    private func segment(_ segment: AttendanceActivityPhase, label: String) -> some View {
        VStack(spacing: DefaultSpacing.spacing4) {
            segmentBar(segment)
                .tint(segment.tint)
            Text(label)
                .appFont(.caption2, color: segment == phase ? segment.tint : .grey500)
        }
    }

    @ViewBuilder
    private func segmentBar(_ segment: AttendanceActivityPhase) -> some View {
        if segment == phase, let interval = runningInterval(of: segment) {
            ProgressView(timerInterval: interval, countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
        } else {
            ProgressView(value: segment.order <= phase.order ? 1.0 : 0.0)
        }
    }

    /// 시간에 따라 차오르는 구간. 결석 구간은 마감과 동시에 가득 차므로 없다.
    private func runningInterval(of segment: AttendanceActivityPhase) -> ClosedRange<Date>? {
        switch segment {
        case .onTime: attributes.checkInStartAt...attributes.onTimeEndAt
        case .late: attributes.onTimeEndAt...attributes.lateEndAt
        case .beforeCheckIn, .closed: nil
        }
    }
}

// MARK: - Phase Style

extension AttendanceActivityPhase {
    /// 출석 전은 시안에 없어 중립 톤으로만 둔다.
    var tint: Color {
        switch self {
        case .beforeCheckIn: .grey500
        case .onTime: .green500
        case .late: .orange500
        case .closed: .red500
        }
    }

    var timerColor: Color {
        self == .closed ? .red500 : .white
    }

    var title: String {
        switch self {
        case .beforeCheckIn: "출석 전"
        case .onTime: "출석 가능"
        case .late: "지각 · 사유 제출"
        case .closed: "출석 마감"
        }
    }

    var symbolName: String {
        switch self {
        case .beforeCheckIn: "clock.fill"
        case .onTime: "checkmark.shield.fill"
        case .late: "doc.badge.clock.fill"
        case .closed: "lock.fill"
        }
    }

    /// 진행 막대에서 구간 선후를 비교하는 순서.
    var order: Int {
        switch self {
        case .beforeCheckIn: 0
        case .onTime: 1
        case .late: 2
        case .closed: 3
        }
    }
}

// MARK: - Constants

fileprivate enum Constants {
    static let lockScreenTimerSize: CGFloat = 40
    static let expandedTimerSize: CGFloat = 44
    static let smallTimerSize: CGFloat = 22
    static let lockScreenContentWidth: CGFloat = 220
    static let lockScreenIconSize: CGFloat = 72
    static let lockScreenIconOverhang: CGFloat = 20
    static let expandedIconSize: CGFloat = 56
    static let badgeSize: CGFloat = 20
    static let badgeCornerRadius: CGFloat = 6
    static let dotSize: CGFloat = 10
    static let glowOpacity: Double = 0.6
    static let backgroundGlowOpacity: Double = 0.35
    static let backgroundGlowRadius: CGFloat = 220
}
