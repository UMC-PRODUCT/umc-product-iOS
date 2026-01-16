//
//  SessionItem.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/16/26.
//

import Foundation

@MainActor
@Observable
final class SessionItem: Identifiable, Equatable {
    let id: SessionID
    let session: Session
    
    private(set) var attendanceLoadable: Loadable<Attendance> = .idle
    private(set) var hasSubmitted: Bool = false
    
    static func == (lhs: SessionItem, rhs: SessionItem) -> Bool {
        lhs.session.id == rhs.session.id
    }
    
    var attendance: Attendance? {
        attendanceLoadable.value
    }
    
    var attendanceStatus: AttendanceStatus {
        attendanceLoadable.value?.status ?? .pending
    }
    
    var isLoading: Bool {
        attendanceLoadable.isLoading
    }
    
    var isSuccess: Bool {
        hasSubmitted || attendanceStatus != .pending
    }
    
    init(session: Session, initialAttendance: Attendance? = nil) {
        self.session = session
        self.id = session.sessionId
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

        // 이번 세션에서 제출함 + 아직 pending → 승인 대기
        if hasSubmitted, attendanceStatus == .pending {
            return "승인 대기 중"
        }

        // 최종 결정됨 (출석 / 지각 / 결석)
        if attendanceStatus != .pending {
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
