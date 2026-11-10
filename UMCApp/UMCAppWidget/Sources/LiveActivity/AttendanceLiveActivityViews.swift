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
        AttendanceCardContent(
            attributes: attributes,
            phase: phase,
            timerSize: Constants.lockScreenTimerSize
        )
        .padding(DefaultSpacing.spacing16)
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

/// 확장 영역은 시간 안내와 전체 폭 진행 단계를 분리해 한눈에 읽히도록 구성한다.
struct AttendanceExpandedContent: View {
    let attributes: AttendanceActivityAttributes
    let phase: AttendanceActivityPhase

    var body: some View {
        AttendanceCardContent(
            attributes: attributes,
            phase: phase,
            timerSize: Constants.expandedTimerSize
        )
        .padding(.horizontal, DefaultSpacing.spacing8)
        .environment(\.colorScheme, .dark)
    }
}

/// 잠금 화면과 확장 아일랜드의 헤더·카운트다운·단계 표시를 같은 구성으로 유지한다.
private struct AttendanceCardContent: View {
    let attributes: AttendanceActivityAttributes
    let phase: AttendanceActivityPhase
    let timerSize: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            AttendancePhaseHeader(phase: phase)

            HStack(alignment: .center, spacing: DefaultSpacing.spacing12) {
                VStack(alignment: .leading, spacing: 0) {
                    AttendanceCountdownText(attributes: attributes, phase: phase)
                        .font(.system(size: timerSize, weight: .bold))
                        .foregroundStyle(phase.timerColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .multilineTextAlignment(.leading)
                    Text(phase.countdownLabel)
                        .appFont(.caption1, color: .white.opacity(0.72))
                        .lineLimit(1)
                }
                .accessibilityElement(children: .combine)
                .frame(maxWidth: .infinity, alignment: .leading)

                AttendancePhaseIllustration(phase: phase)
            }
            AttendancePhaseProgressBar(attributes: attributes, phase: phase)
        }
    }
}

/// 카메라 옆의 좁은 영역 대신 전체 폭 안쪽에 앱 표시와 단계 문구를 함께 둔다.
private struct AttendancePhaseHeader: View {
    let phase: AttendanceActivityPhase

    var body: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            AttendanceActivityHeader(title: "UMC", phase: phase)
            Spacer(minLength: DefaultSpacing.spacing8)
            Text(phase.title)
                .appFont(.caption1, weight: .semibold, color: phase.tint)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.trailing)
                .layoutPriority(1)
        }
    }
}

/// 투명 배경의 3D 렌더 이미지를 고정된 안전 영역 안에 비율을 유지해 표시한다.
private struct AttendancePhaseIllustration: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let phase: AttendanceActivityPhase

    var body: some View {
        ZStack {
            illustration
                // 단계만 식별자로 써서 타이머 갱신에는 진입 효과를 반복하지 않는다.
                .id(phase)
                .transition(illustrationTransition)
        }
        .frame(
            width: Constants.expandedIllustrationSize,
            height: Constants.expandedIllustrationSize
        )
        .animation(
            reduceMotion
                ? .easeOut(duration: Constants.illustrationFadeDuration)
                : .spring(duration: Constants.illustrationSpringDuration, bounce: 0.2),
            value: phase
        )
        .accessibilityHidden(true)
    }

    private var illustration: some View {
        Group {
            if let imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
            } else {
                AttendancePhaseIcon(phase: phase, size: Constants.expandedIconSize)
            }
        }
        .frame(
            width: Constants.expandedIllustrationSize,
            height: Constants.expandedIllustrationSize
        )
    }

    /// Live Activity 갱신 시 짧게 올라오며 안착한다. 동작 줄이기는 투명도만 바꾼다.
    private var illustrationTransition: AnyTransition {
        if reduceMotion { return .opacity }
        return .asymmetric(
            insertion: .offset(y: Constants.illustrationEntryOffset)
                .combined(with: .scale(scale: 0.94))
                .combined(with: .opacity),
            removal: .opacity
        )
    }

    private var imageName: String? {
        switch phase {
        case .beforeCheckIn: nil
        case .onTime: "AttendanceOnTime3D"
        case .late: "AttendanceLate3D"
        case .closed: "AttendanceClosed3D"
        }
    }
}

// MARK: - Components

/// 실제 앱 아이콘 + 세션 제목.
struct AttendanceActivityHeader: View {
    let title: String
    let phase: AttendanceActivityPhase

    var body: some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            // AppIcon.icon을 Xcode가 렌더링한 실제 앱 아이콘의 정적 사본이다.
            Image("UMCAppIcon")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: Constants.badgeSize, height: Constants.badgeSize)
                .accessibilityHidden(true)
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
            .accessibilityLabel(phase.title)
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
            .accessibilityHidden(true)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("출석 시간 단계: 출석, 지각, 결석. 현재 \(phase.title)")
    }

    private func segment(_ segment: AttendanceActivityPhase, label: String) -> some View {
        VStack(spacing: DefaultSpacing.spacing4) {
            segmentBar(segment)
                .tint(segment.tint)
                .frame(height: Constants.progressHeight)
            HStack(spacing: DefaultSpacing.spacing4) {
                if segment == phase {
                    Circle()
                        .fill(segment.tint)
                        .frame(width: Constants.currentPhaseDotSize,
                               height: Constants.currentPhaseDotSize)
                }
                Text(label)
                    .appFont(
                        .caption2,
                        weight: segment == phase ? .semibold : .regular,
                        color: segment == phase ? segment.tint : .white.opacity(0.6)
                    )
            }
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
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

    /// 숫자가 가리키는 경계이며, 개인의 출석 처리 결과를 뜻하지 않는다.
    var countdownLabel: String {
        switch self {
        case .beforeCheckIn: "출석 시작까지"
        case .onTime: "정시 출석 마감까지"
        case .late: "지각 마감까지"
        case .closed: "출석 시간이 종료됐어요"
        }
    }

    var symbolName: String {
        switch self {
        case .beforeCheckIn: "clock.fill"
        case .onTime: "location.circle.fill"
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
    static let expandedTimerSize: CGFloat = 32
    static let smallTimerSize: CGFloat = 22
    static let expandedIconSize: CGFloat = 32
    static let expandedIllustrationSize: CGFloat = 56
    static let illustrationEntryOffset: CGFloat = 6
    static let illustrationSpringDuration: TimeInterval = 0.4
    static let illustrationFadeDuration: TimeInterval = 0.18
    static let progressHeight: CGFloat = 4
    static let currentPhaseDotSize: CGFloat = 4
    static let badgeSize: CGFloat = 20
    static let dotSize: CGFloat = 10
}
