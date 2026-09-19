//
//  AttendanceLiveActivityCoordinator.swift
//  UMCApp
//
//  Created by euijjang97 on 9/19/26.
//

import ActivityDomain
import ActivityKit
import CoreWidgetShared
import Foundation
import HomeDomain

/// 출석 세션 Live Activity 의 시작·단계 갱신·종료를 맡는다.
///
/// 서버 푸시 없이 로컬로만 돈다. 앱이 포그라운드에 있는 동안 출석 가능 일정을 조회해, 요청
/// 가능 구간(정시·지각)에 든 미제출 일정마다 Live Activity 를 하나씩 띄우고 단계 경계마다 다시
/// 맞춘다. 백그라운드에서는 갱신할 수 없으므로 단계 종료 시각을 `staleDate` 로 걸어 위젯이
/// 다음 단계로 그리게 한다(`AttendanceLiveActivity.displayedPhase`).
@MainActor
enum AttendanceLiveActivityCoordinator {

    private typealias AttendanceActivity = Activity<AttendanceActivityAttributes>

    // MARK: - Constants

    private enum Constants {
        /// 마감 상태("출석 마감")를 잠금 화면에 남겨 두는 시간
        static let closedDismissalDelay: TimeInterval = 10 * 60
        /// 경계 직후에 깨어나 판정이 다음 단계로 넘어가 있도록 두는 여유
        static let boundaryMargin: TimeInterval = 1
    }

    // MARK: - Function

    /// 일정 조회 → 동기화 → 다음 단계 경계까지 대기를 반복한다.
    ///
    /// 진행 중인 Live Activity 가 없거나 조회에 실패하면 끝난다 — Live Activity 는 보조 표시라
    /// 실패를 사용자에게 알리지 않는다. 호출한 Task 가 취소되면(백그라운드 진입) 대기에서
    /// 바로 빠져나온다.
    static func run(useCase: ChallengerAttendanceUseCaseProtocol) async {
        while !Task.isCancelled {
            guard let schedules = try? await useCase.fetchAvailableSchedules() else { return }
            let now = Date()
            await sync(with: schedules, now: now)

            guard let boundary = nextBoundary(after: now) else { return }
            let delay = boundary.timeIntervalSinceNow + Constants.boundaryMargin
            try? await Task.sleep(for: .seconds(max(delay, 0)))
        }
    }

    /// 대상 일정과 진행 중인 Live Activity 를 맞춘다.
    ///
    /// 진행 중인 것은 단계가 바뀌었으면 갱신하고, 대상에서 빠졌으면(출석 요청·마감) 끝낸다.
    /// 그다음 아직 없는 대상만 새로 띄우므로 같은 일정이 두 번 뜨지 않는다.
    static func sync(with schedules: [ScheduleDetailData], now: Date) async {
        let targetIds = Set(schedules.compactMap { attributes(for: $0, now: now)?.scheduleId })

        for activity in liveActivities {
            let attributes = activity.attributes
            let phase = attributes.phase(at: now)

            guard targetIds.contains(attributes.scheduleId), phase != .closed else {
                await end(activity, now: now)
                continue
            }
            if phase != activity.content.state.phase {
                await activity.update(content(for: phase, of: attributes))
            }
        }

        // 사용자가 Live Activity 를 꺼 두었으면 조용히 건너뛴다.
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let runningIds = Set(liveActivities.map(\.attributes.scheduleId))
        for schedule in schedules {
            guard let attributes = attributes(for: schedule, now: now),
                  !runningIds.contains(attributes.scheduleId)
            else { continue }

            _ = try? AttendanceActivity.request(
                attributes: attributes,
                content: content(for: attributes.phase(at: now), of: attributes),
                pushType: nil
            )
        }
    }

    /// 출석을 요청한 일정의 Live Activity 를 바로 내린다.
    static func end(scheduleId: String) async {
        for activity in liveActivities where activity.attributes.scheduleId == scheduleId {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    /// 로그아웃 등으로 탭 셸을 떠날 때 전부 내린다.
    static func endAll() async {
        for activity in liveActivities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    // MARK: - Private Function

    /// 아직 끝나지 않은 출석 Live Activity
    private static var liveActivities: [AttendanceActivity] {
        AttendanceActivity.activities.filter {
            $0.activityState == .active || $0.activityState == .stale
        }
    }

    /// 일정이 Live Activity 대상이면 그 속성, 아니면 `nil`.
    ///
    /// 출석 정책이 있고, 아직 출석을 요청하지 않았으며(`nil`·`beforeAttendance`), 지금이
    /// 정시·지각 구간인 일정만 대상이다. 정책 시각 순서가 어긋난 일정은 위젯이 타이머 구간
    /// (`ClosedRange`)을 만들 수 없으므로 뺀다.
    private static func attributes(
        for schedule: ScheduleDetailData,
        now: Date
    ) -> AttendanceActivityAttributes? {
        guard let policy = schedule.attendancePolicy,
              schedule.attendanceStatus == nil || schedule.attendanceStatus == .beforeAttendance,
              policy.checkInStartAt <= policy.onTimeEndAt,
              policy.onTimeEndAt <= policy.lateEndAt
        else { return nil }

        let attributes = AttendanceActivityAttributes(
            scheduleId: schedule.scheduleId,
            title: schedule.name,
            checkInStartAt: policy.checkInStartAt,
            onTimeEndAt: policy.onTimeEndAt,
            lateEndAt: policy.lateEndAt
        )
        switch attributes.phase(at: now) {
        case .onTime, .late:
            return attributes
        case .beforeCheckIn, .closed:
            return nil
        }
    }

    /// 마감이 지났으면 마감 상태를 잠시 남기고, 그 외(출석 요청 등)는 바로 내린다.
    private static func end(_ activity: AttendanceActivity, now: Date) async {
        let attributes = activity.attributes
        guard attributes.phase(at: now) == .closed else {
            await activity.end(nil, dismissalPolicy: .immediate)
            return
        }

        let dismissAt = attributes.lateEndAt.addingTimeInterval(Constants.closedDismissalDelay)
        await activity.end(
            content(for: .closed, of: attributes),
            dismissalPolicy: .after(dismissAt)
        )
    }

    /// 진행 중인 Live Activity 가운데 가장 먼저 오는 단계 경계.
    private static func nextBoundary(after now: Date) -> Date? {
        liveActivities
            .compactMap { $0.attributes.endDate(of: $0.attributes.phase(at: now)) }
            .min()
    }

    private static func content(
        for phase: AttendanceActivityPhase,
        of attributes: AttendanceActivityAttributes
    ) -> ActivityContent<AttendanceActivityAttributes.ContentState> {
        ActivityContent(state: .init(phase: phase), staleDate: attributes.endDate(of: phase))
    }
}
