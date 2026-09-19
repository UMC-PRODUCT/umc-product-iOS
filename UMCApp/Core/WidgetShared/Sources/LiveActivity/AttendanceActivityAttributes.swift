//
//  AttendanceActivityAttributes.swift
//  CoreWidgetShared
//
//  Created by euijjang97 on 9/19/26.
//

import ActivityKit
import Foundation

/// 출석 세션 Live Activity 의 고정 속성과 동적 상태.
///
/// 앱(시작·갱신·종료)과 위젯 익스텐션(렌더링)이 같은 타입을 봐야 하므로 공유 모듈에 둔다.
/// 카운트다운은 세 정책 시각만으로 로컬에서 그리므로 서버 푸시 없이 동작한다.
public struct AttendanceActivityAttributes: ActivityAttributes {

    /// 현재 출석 단계.
    ///
    /// 단계 하나뿐이어도 enum 을 그대로 쓰지 않고 구조체로 감싼다 — 추후 APNs 로
    /// 갱신할 때 `content-state` 가 JSON 객체여야 하기 때문이다.
    public struct ContentState: Codable, Hashable, Sendable {
        public let phase: AttendanceActivityPhase

        public init(phase: AttendanceActivityPhase) {
            self.phase = phase
        }
    }

    // MARK: - Property

    /// 서버 일정 ID (정수를 String 으로 직렬화한 값)
    public let scheduleId: String
    public let title: String
    public let checkInStartAt: Date
    public let onTimeEndAt: Date
    public let lateEndAt: Date

    // MARK: - Init

    public init(
        scheduleId: String,
        title: String,
        checkInStartAt: Date,
        onTimeEndAt: Date,
        lateEndAt: Date
    ) {
        self.scheduleId = scheduleId
        self.title = title
        self.checkInStartAt = checkInStartAt
        self.onTimeEndAt = onTimeEndAt
        self.lateEndAt = lateEndAt
    }

    // MARK: - Function

    /// `date` 시점의 출석 단계.
    ///
    /// 경계 판정은 출석 화면(`ChallengerAttendanceViewModel.currentTimeWindow`)과 같다 —
    /// 마감 시각과 같은 순간까지는 해당 단계로 본다.
    public func phase(at date: Date) -> AttendanceActivityPhase {
        if date < checkInStartAt { return .beforeCheckIn }
        if date <= onTimeEndAt { return .onTime }
        if date <= lateEndAt { return .late }
        return .closed
    }

    /// `phase` 가 끝나는 시각. 마감(`closed`)은 다음 단계가 없으므로 `nil`.
    ///
    /// 앱이 백그라운드에 있어도 단계가 넘어가 보이도록 `staleDate` 로 쓴다.
    public func endDate(of phase: AttendanceActivityPhase) -> Date? {
        switch phase {
        case .beforeCheckIn: checkInStartAt
        case .onTime: onTimeEndAt
        case .late: lateEndAt
        case .closed: nil
        }
    }
}

// MARK: - AttendanceActivityPhase

/// 출석 Live Activity 의 단계 — 출석 전 → 정시 → 지각 → 마감 순으로만 흐른다.
public enum AttendanceActivityPhase: String, Codable, Hashable, Sendable {
    case beforeCheckIn
    case onTime
    case late
    case closed

    /// 바로 다음 단계. `staleDate` 가 지난 콘텐츠를 다음 단계로 그릴 때 쓴다.
    public var next: AttendanceActivityPhase {
        switch self {
        case .beforeCheckIn: .onTime
        case .onTime: .late
        case .late, .closed: .closed
        }
    }
}
