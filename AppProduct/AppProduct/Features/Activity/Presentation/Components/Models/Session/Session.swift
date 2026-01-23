//
//  Session.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/5/26.
//

import Foundation

@MainActor
@Observable
final class Session: Identifiable, Equatable {
    let id: SessionID
    let info: SessionInfo

    private(set) var attendanceLoadable: Loadable<Attendance> = .idle
    private(set) var hasSubmitted: Bool = false

    static func == (lhs: Session, rhs: Session) -> Bool {
        lhs.id == rhs.id
        && lhs.info.id == rhs.info.id
    }

    var attendance: Attendance? {
        attendanceLoadable.value
    }

    var attendanceStatus: AttendanceStatus {
        // 제출 완료 + 아직 확정되지 않은 경우 → 승인 대기
        if hasSubmitted, attendanceLoadable.value?.status == .beforeAttendance {
            return .pendingApproval
        }
        return attendanceLoadable.value?.status ?? .beforeAttendance
    }

    var isLoading: Bool {
        attendanceLoadable.isLoading
    }

    var isSuccess: Bool {
        hasSubmitted || (attendanceStatus != .beforeAttendance && attendanceStatus != .pendingApproval)
    }

    /// 출석 가능 여부 (출석 전 또는 승인 대기 상태)
    var isAttendanceAvailable: Bool {
        attendanceStatus == .beforeAttendance || attendanceStatus == .pendingApproval
    }

    init(info: SessionInfo, initialAttendance: Attendance? = nil) {
        self.info = info
        self.id = info.sessionId
        if let attendance = initialAttendance {
            attendanceLoadable = .loaded(attendance)
        }
    }

    func updateState(_ state: Loadable<Attendance>) {
        self.attendanceLoadable = state
    }

    func markSubmitted() {
        hasSubmitted = true
    }

    func buttonTitle(
        isLocationAuthorized: Bool,
        isInsideGeofence: Bool,
        timeWindow: AttendanceTimeWindow
    ) -> String {
        if isLoading {
            return "출석 처리 중..."
        }

        // 승인 대기 상태
        if attendanceStatus == .pendingApproval {
            return "승인 대기 중"
        }

        // 최종 결정됨 (출석 / 지각 / 결석)
        if attendanceStatus != .beforeAttendance && attendanceStatus != .pendingApproval {
            return attendanceStatus.displayText
        }

        // 시간대 체크
        switch timeWindow {
        case .tooEarly:
            return "아직 출석 시간이 아닙니다"
        case .lateWindow:
            return "지각 - 사유를 제출하세요"
        case .expired:
            return "출석 마감됨"
        case .onTime:
            break  // 아래 조건들 계속 체크
        }

        if !isLocationAuthorized {
            return "위치 권한 필요"
        }

        if !isInsideGeofence {
            return "출석 범위 밖"
        }

        return "현 위치로 출석체크"
    }
}
