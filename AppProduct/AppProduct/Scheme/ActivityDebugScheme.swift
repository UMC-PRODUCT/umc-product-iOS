//
//  ActivityDebugScheme.swift
//  AppProduct
//
//  Created by euijjang97 on 2/18/26.
//

import Foundation

#if DEBUG
enum ActivityDebugState: String {
    case loading
    case loaded
    case failed

    static func fromLaunchArgument() -> ActivityDebugState? {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-activityDebugState"),
           arguments.indices.contains(index + 1) {
            return ActivityDebugState(rawValue: arguments[index + 1])
        }

        if let environmentValue = ProcessInfo.processInfo.environment["ACTIVITY_DEBUG_STATE"] {
            return ActivityDebugState(rawValue: environmentValue)
        }

        return nil
    }

    func apply(to viewModel: ActivityViewModel) {
        viewModel.seedForDebugState(
            sessionsState: sessionsLoadable,
            userId: debugUserId
        )
    }

    private var sessionsLoadable: Loadable<[Session]> {
        switch self {
        case .loading:
            return .loading
        case .loaded:
            return .loaded(Self.debugSessions)
        case .failed:
            return .failed(.unknown(message: "활동 데이터를 불러오지 못했습니다."))
        }
    }

    private var debugUserId: UserID {
        UserID(value: "123")
    }

    private static var debugSessions: [Session] {
        let calendar = Calendar.current
        let now = Date()
        let userId = UserID(value: "123")

        func date(_ dayOffset: Int, _ hour: Int, _ minute: Int) -> Date {
            let baseDate = calendar.date(byAdding: .day, value: dayOffset, to: now) ?? now
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: baseDate) ?? baseDate
        }

        return [
            Session(
                info: SessionInfo(
                    sessionId: SessionID(value: "1001"),
                    icon: .Activity.profile,
                    title: "iOS 파트 정규 세션 OT",
                    week: 6,
                    startTime: date(-18, 19, 0),
                    endTime: date(-18, 21, 0),
                    location: Coordinate(
                        latitude: 37.566295,
                        longitude: 126.977945
                    )
                ),
                initialAttendance: Attendance(
                    sessionId: SessionID(value: "1001"),
                    userId: userId,
                    type: .gps,
                    status: .present,
                    locationVerification: LocationVerification(
                        isVerified: true,
                        coordinate: Coordinate(latitude: 37.566295, longitude: 126.977945),
                        address: Address(
                            fullAddress: "서울특별시 중구 세종대로 110",
                            city: "서울특별시",
                            district: "중구"
                        ),
                        verifiedAt: date(-18, 18, 57)
                    ),
                    reason: nil
                )
            ),
            Session(
                info: SessionInfo(
                    sessionId: SessionID(value: "1002"),
                    icon: .Activity.profile,
                    title: "공통 해커톤 기획 회의",
                    week: 7,
                    startTime: date(-11, 18, 30),
                    endTime: date(-11, 20, 30),
                    location: Coordinate(
                        latitude: 37.555101,
                        longitude: 126.936784
                    )
                ),
                initialAttendance: Attendance(
                    sessionId: SessionID(value: "1002"),
                    userId: userId,
                    type: .reason,
                    status: .late,
                    locationVerification: nil,
                    reason: "퇴근 지연으로 12분 늦었습니다."
                )
            ),
            Session(
                info: SessionInfo(
                    sessionId: SessionID(value: "1003"),
                    icon: .Activity.profile,
                    title: "지부 연합 네트워킹 데이",
                    week: 8,
                    startTime: date(-6, 14, 0),
                    endTime: date(-6, 17, 0),
                    location: Coordinate(
                        latitude: 37.546997,
                        longitude: 127.095986
                    )
                ),
                initialAttendance: Attendance(
                    sessionId: SessionID(value: "1003"),
                    userId: userId,
                    type: .reason,
                    status: .absent,
                    locationVerification: nil,
                    reason: "개인 사정으로 참석하지 못했습니다."
                )
            ),
            Session(
                info: SessionInfo(
                    sessionId: SessionID(value: "1004"),
                    icon: .Activity.profile,
                    title: "iOS 파트 코드리뷰 스터디",
                    week: 9,
                    startTime: date(-2, 19, 30),
                    endTime: date(-2, 21, 30),
                    location: Coordinate(
                        latitude: 37.497942,
                        longitude: 127.027621
                    )
                ),
                initialAttendance: Attendance(
                    sessionId: SessionID(value: "1004"),
                    userId: userId,
                    type: .reason,
                    status: .pendingApproval,
                    locationVerification: nil,
                    reason: "교통 지연으로 지각 사유 제출"
                )
            ),
            Session(
                info: SessionInfo(
                    sessionId: SessionID(value: "1005"),
                    icon: .Activity.profile,
                    title: "정규 세션 10주차 (UIKit 심화)",
                    week: 10,
                    startTime: date(0, 19, 0),
                    endTime: date(0, 21, 0),
                    location: Coordinate(
                        latitude: 37.582967,
                        longitude: 127.010527
                    )
                ),
                initialAttendance: nil
            ),
            Session(
                info: SessionInfo(
                    sessionId: SessionID(value: "1006"),
                    icon: .Activity.profile,
                    title: "공통 해커톤 중간 점검",
                    week: 11,
                    startTime: date(2, 20, 0),
                    endTime: date(2, 22, 0),
                    location: Coordinate(
                        latitude: 37.503193,
                        longitude: 127.044361
                    )
                ),
                initialAttendance: nil
            ),
            Session(
                info: SessionInfo(
                    sessionId: SessionID(value: "1007"),
                    icon: .Activity.profile,
                    title: "최종 발표 리허설",
                    week: 12,
                    startTime: date(6, 18, 30),
                    endTime: date(6, 21, 30),
                    location: Coordinate(
                        latitude: 37.484770,
                        longitude: 126.896997
                    )
                ),
                initialAttendance: nil
            )
        ]
    }
}
#endif
