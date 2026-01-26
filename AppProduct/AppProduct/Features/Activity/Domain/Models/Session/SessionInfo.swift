//
//  SessionInfo.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/16/26.
//

import Foundation
import SwiftUI

<<<<<<<< HEAD:AppProduct/AppProduct/Features/Activity/Domain/Models/Session/SessionInfo.swift
/// 스터디/세미나 세션 정보
///
/// 출석 체크, 일정 표시 등에 사용되는 세션 데이터 모델입니다.
/// - Note: `id`는 SwiftUI List/ForEach용, `sessionId`는 서버 API용
struct SessionInfo: Identifiable, Equatable {
    let id: UUID = .init()
    let sessionId: SessionID
    let category: ScheduleIconCategory = .general
    let icon: ImageResource
    let title: String
    let week: Int
    let startTime: Date
    let endTime: Date
    let location: Coordinate
}
========
@MainActor
@Observable
final class Session: Identifiable, Equatable {
    let id: SessionID
    let info: SessionInfo
>>>>>>>> ef4f973 (✨ [Feat] GPS 기반 출석 시스템 UI 구현 (#77) (#106)):AppProduct/AppProduct/Features/Activity/Presentation/Components/Models/Session/Session.swift

    private(set) var attendanceLoadable: Loadable<Attendance> = .idle
    private(set) var hasSubmitted: Bool = false

<<<<<<<< HEAD:AppProduct/AppProduct/Features/Activity/Domain/Models/Session/SessionInfo.swift
extension SessionInfo {
    /// 세션 위치를 MapKit 좌표로 변환
    func toCLLocationCoordinate2D() -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
========
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

    /// 출석 요청 가능 여부 (도메인 규칙)
    ///
    /// - Parameters:
    ///   - timeWindow: 현재 시간대 (정시/지각/마감 등)
    ///   - isInsideGeofence: 지오펜스 내부 여부
    ///   - isLocationAuthorized: 위치 권한 허용 여부
    /// - Returns: 출석 요청 버튼 활성화 여부
    func canRequestAttendance(
        timeWindow: AttendanceTimeWindow,
        isInsideGeofence: Bool,
        isLocationAuthorized: Bool
    ) -> Bool {
        timeWindow == .onTime
        && isInsideGeofence
        && isLocationAuthorized
        && !isLoading
        && !hasSubmitted
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
>>>>>>>> ef4f973 (✨ [Feat] GPS 기반 출석 시스템 UI 구현 (#77) (#106)):AppProduct/AppProduct/Features/Activity/Presentation/Components/Models/Session/Session.swift
    }
}
