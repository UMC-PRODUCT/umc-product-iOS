//
//  AttendanceLiveActivity.swift
//  UMCAppWidget
//
//  Created by euijjang97 on 9/19/26.
//

import ActivityKit
import CoreDesignSystem
import CoreWidgetShared
import SwiftUI
import WidgetKit

/// 출석 세션 카운트다운 Live Activity — 잠금 화면·Dynamic Island·워치 Smart Stack.
///
/// 카운트다운과 진행 막대는 `timerInterval` 기반이라 시스템이 초 단위로 그린다. 앱은 단계가
/// 바뀔 때만 상태를 갱신하고, 백그라운드에서는 `staleDate` 가 지난 콘텐츠를 다음 단계로 그린다.
struct AttendanceLiveActivity: Widget {

    // MARK: - Body

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AttendanceActivityAttributes.self) { context in
            AttendanceLockScreenView(
                attributes: context.attributes,
                phase: context.displayedPhase
            )
            .activityBackgroundTint(.black)
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let attributes = context.attributes
            let phase = context.displayedPhase

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    AttendanceActivityHeader(title: attributes.title, phase: phase)
                        .dynamicIsland(verticalPlacement: .belowIfTooWide)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    AttendanceExpandedContent(attributes: attributes, phase: phase)
                }
            } compactLeading: {
                AttendancePhaseDot(phase: phase)
            } compactTrailing: {
                AttendanceCountdownText(attributes: attributes, phase: phase)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(phase.tint)
                    .multilineTextAlignment(.trailing)
                    // 타이머 Text 는 가능한 최대 폭을 차지하므로 폭을 고정한다.
                    .frame(width: Constants.compactTimerWidth)
            } minimal: {
                AttendancePhaseDot(phase: phase)
            }
            .keylineTint(phase.tint)
        }
        .supplementalActivityFamilies([.small])
    }
}

// MARK: - Constants

fileprivate enum Constants {
    static let compactTimerWidth: CGFloat = 48
}

// MARK: - ActivityViewContext

private extension ActivityViewContext<AttendanceActivityAttributes> {
    /// 화면에 그릴 단계.
    ///
    /// 앱이 살아 있을 때는 단계 경계마다 상태를 갱신하지만, 백그라운드에서는 갱신할 수
    /// 없다. 대신 단계 종료 시각을 `staleDate` 로 걸어 두었으므로, stale 이 되면 다음
    /// 단계로 넘어간 것으로 보고 그린다.
    var displayedPhase: AttendanceActivityPhase {
        isStale ? state.phase.next : state.phase
    }
}

// MARK: - Preview

#if DEBUG
#Preview(
    "잠금 화면",
    as: .content,
    using: AttendanceActivityAttributes(
        scheduleId: "1",
        title: "iOS 스터디 6주차",
        checkInStartAt: .now.addingTimeInterval(-60),
        onTimeEndAt: .now.addingTimeInterval(512),
        lateEndAt: .now.addingTimeInterval(1_800)
    )
) {
    AttendanceLiveActivity()
} contentStates: {
    AttendanceActivityAttributes.ContentState(phase: .beforeCheckIn)
    AttendanceActivityAttributes.ContentState(phase: .onTime)
    AttendanceActivityAttributes.ContentState(phase: .late)
    AttendanceActivityAttributes.ContentState(phase: .closed)
}
#endif
