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
    case allLoading
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
        case .allLoading:
            return .loading
        case .loaded:
            return .loaded(Self.debugSessions)
        case .failed:
            return .failed(.unknown(message: "활동 데이터를 불러오지 못했습니다."))
        }
    }

    var isAllScreensLoading: Bool {
        switch self {
        case .allLoading, .failed:
            return true
        case .loading, .loaded:
            return false
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

    // MARK: - Debug Fixtures

    static let loadedMembers: [MemberManagementItem] = {
        let now = Date()
        let perfect: [MemberAttendanceRecord] = [
            MemberAttendanceRecord(sessionTitle: "OT 및 Git 기초", week: 1, status: .present),
            MemberAttendanceRecord(sessionTitle: "iOS SwiftUI 기초", week: 2, status: .present),
            MemberAttendanceRecord(sessionTitle: "네비게이션 & 데이터 플로우", week: 3, status: .present),
            MemberAttendanceRecord(sessionTitle: "API 통신 & 네트워킹", week: 4, status: .present),
            MemberAttendanceRecord(sessionTitle: "상태 관리 & MVVM 패턴", week: 5, status: .present),
            MemberAttendanceRecord(sessionTitle: "클린 아키텍처 & DI", week: 6, status: .present),
            MemberAttendanceRecord(sessionTitle: "프로젝트 중간 발표", week: 7, status: .present)
        ]

        let good: [MemberAttendanceRecord] = [
            MemberAttendanceRecord(sessionTitle: "OT 및 Git 기초", week: 1, status: .present),
            MemberAttendanceRecord(sessionTitle: "iOS SwiftUI 기초", week: 2, status: .present),
            MemberAttendanceRecord(sessionTitle: "네비게이션 & 데이터 플로우", week: 3, status: .late),
            MemberAttendanceRecord(sessionTitle: "API 통신 & 네트워킹", week: 4, status: .present),
            MemberAttendanceRecord(sessionTitle: "상태 관리 & MVVM 패턴", week: 5, status: .present),
            MemberAttendanceRecord(sessionTitle: "클린 아키텍처 & DI", week: 6, status: .present),
            MemberAttendanceRecord(sessionTitle: "프로젝트 중간 발표", week: 7, status: .present)
        ]

        let average: [MemberAttendanceRecord] = [
            MemberAttendanceRecord(sessionTitle: "OT 및 Git 기초", week: 1, status: .present),
            MemberAttendanceRecord(sessionTitle: "iOS SwiftUI 기초", week: 2, status: .late),
            MemberAttendanceRecord(sessionTitle: "네비게이션 & 데이터 플로우", week: 3, status: .present),
            MemberAttendanceRecord(sessionTitle: "API 통신 & 네트워킹", week: 4, status: .present),
            MemberAttendanceRecord(sessionTitle: "상태 관리 & MVVM 패턴", week: 5, status: .late),
            MemberAttendanceRecord(sessionTitle: "클린 아키텍처 & DI", week: 6, status: .present),
            MemberAttendanceRecord(sessionTitle: "프로젝트 중간 발표", week: 7, status: .present)
        ]

        let poor: [MemberAttendanceRecord] = [
            MemberAttendanceRecord(sessionTitle: "OT 및 Git 기초", week: 1, status: .late),
            MemberAttendanceRecord(sessionTitle: "iOS SwiftUI 기초", week: 2, status: .absent),
            MemberAttendanceRecord(sessionTitle: "네비게이션 & 데이터 플로우", week: 3, status: .late),
            MemberAttendanceRecord(sessionTitle: "API 통신 & 네트워킹", week: 4, status: .absent),
            MemberAttendanceRecord(sessionTitle: "상태 관리 & MVVM 패턴", week: 5, status: .present),
            MemberAttendanceRecord(sessionTitle: "클린 아키텍처 & DI", week: 6, status: .present),
            MemberAttendanceRecord(sessionTitle: "프로젝트 중간 발표", week: 7, status: .present)
        ]

        let nonePenalty: [OperatorMemberPenaltyHistory] = []
        let onePenalty: [OperatorMemberPenaltyHistory] = [
            OperatorMemberPenaltyHistory(
                date: now.addingTimeInterval(-7 * 24 * 60 * 60),
                reason: "세션 지각",
                penaltyScore: 1.0
            )
        ]
        let twoPenalty: [OperatorMemberPenaltyHistory] = [
            OperatorMemberPenaltyHistory(
                date: now.addingTimeInterval(-14 * 24 * 60 * 60),
                reason: "세션 지각",
                penaltyScore: 1.0
            ),
            OperatorMemberPenaltyHistory(
                date: now.addingTimeInterval(-7 * 24 * 60 * 60),
                reason: "세션 결석 (사유 없음)",
                penaltyScore: 1.0
            )
        ]
        let threePenalty: [OperatorMemberPenaltyHistory] = [
            OperatorMemberPenaltyHistory(
                date: now.addingTimeInterval(-21 * 24 * 60 * 60),
                reason: "세션 지각 (교통 체증)",
                penaltyScore: 1.0
            ),
            OperatorMemberPenaltyHistory(
                date: now.addingTimeInterval(-14 * 24 * 60 * 60),
                reason: "워크북 미제출",
                penaltyScore: 0.5
            ),
            OperatorMemberPenaltyHistory(
                date: now.addingTimeInterval(-7 * 24 * 60 * 60),
                reason: "세션 결석 (사유 없음)",
                penaltyScore: 1.0
            )
        ]

        return [
            .init(
                profile: "https://picsum.photos/seed/member_001/80",
                name: "이예지",
                nickname: "소피",
                generation: "9기",
                school: "가천대학교",
                position: "Part Leader",
                part: .front(type: .ios),
                penalty: 0,
                badge: false,
                managementTeam: .schoolPartLeader,
                attendanceRecords: perfect,
                penaltyHistory: nonePenalty
            ),
            .init(
                profile: "https://picsum.photos/seed/member_002/80",
                name: "김철수",
                nickname: "철수",
                generation: "9기",
                school: "한성대학교",
                position: "Member",
                part: .front(type: .android),
                penalty: 1,
                badge: false,
                managementTeam: .challenger,
                attendanceRecords: average,
                penaltyHistory: twoPenalty
            ),
            .init(
                profile: "https://picsum.photos/seed/member_003/80",
                name: "박영희",
                nickname: "영희",
                generation: "9기",
                school: "서울대학교",
                position: "Member",
                part: .server(type: .spring),
                penalty: 0,
                badge: false,
                managementTeam: .challenger,
                attendanceRecords: good,
                penaltyHistory: onePenalty
            ),
            .init(
                profile: "https://picsum.photos/seed/member_004/80",
                name: "최민수",
                nickname: "민수",
                generation: "9기",
                school: "숭실대학교",
                position: "Member",
                part: .front(type: .web),
                penalty: 2,
                badge: false,
                managementTeam: .challenger,
                attendanceRecords: poor,
                penaltyHistory: threePenalty
            ),
            .init(
                profile: "https://picsum.photos/seed/member_005/80",
                name: "정다은",
                nickname: "다은",
                generation: "9기",
                school: "동국대학교",
                position: "Member",
                part: .design,
                penalty: 0,
                badge: true,
                managementTeam: .challenger,
                attendanceRecords: good,
                penaltyHistory: nonePenalty
            ),
            .init(
                profile: "https://picsum.photos/seed/member_006/80",
                name: "이예찬",
                nickname: "에린",
                generation: "9기",
                school: "한성대학교",
                position: "Member",
                part: .pm,
                penalty: 5,
                badge: false,
                managementTeam: .challenger,
                attendanceRecords: average,
                penaltyHistory: onePenalty + [
                    OperatorMemberPenaltyHistory(
                        date: now.addingTimeInterval(-3 * 24 * 60 * 60),
                        reason: "워크북 미제출",
                        penaltyScore: 1.0
                    )
                ]
            ),
            .init(
                profile: "https://picsum.photos/seed/member_007/80",
                name: "조미림",
                nickname: "미림",
                generation: "9기",
                school: "한양대학교",
                position: "Member",
                part: .front(type: .ios),
                penalty: 0,
                badge: false,
                managementTeam: .challenger,
                attendanceRecords: perfect,
                penaltyHistory: nonePenalty
            ),
            .init(
                profile: "https://picsum.photos/seed/member_008/80",
                name: "이신입",
                nickname: "신입",
                generation: "9기",
                school: "서울여자대학교",
                position: "Member",
                part: .front(type: .ios),
                penalty: 0,
                badge: false,
                managementTeam: .challenger,
                attendanceRecords: [],
                penaltyHistory: onePenalty
            )
        ]
    }()

    static let availableAttendanceSchedules: [AvailableAttendanceSchedule] = [
        AvailableAttendanceSchedule(
            scheduleId: 1001,
            scheduleName: "iOS 파트 정규 세션 OT",
            tags: ["SEMINAR", "IOS", "COMMON"],
            startTime: "19:00:00",
            endTime: "21:00:00",
            sheetId: 1001,
            recordId: 1001,
            status: .present,
            statusDisplay: "출석",
            locationVerified: true
        ),
        AvailableAttendanceSchedule(
            scheduleId: 1002,
            scheduleName: "공통 해커톤 기획 회의",
            tags: ["HACKATHON", "PM"],
            startTime: "18:30:00",
            endTime: "20:30:00",
            sheetId: 1002,
            recordId: 1002,
            status: .present,
            statusDisplay: "출석",
            locationVerified: true
        ),
        AvailableAttendanceSchedule(
            scheduleId: 1003,
            scheduleName: "지부 연합 네트워킹 데이",
            tags: ["NETWORK", "EVENT"],
            startTime: "14:00:00",
            endTime: "16:30:00",
            sheetId: 1003,
            recordId: 1003,
            status: .late,
            statusDisplay: "지각",
            locationVerified: false
        ),
        AvailableAttendanceSchedule(
            scheduleId: 1004,
            scheduleName: "iOS 파트 코드리뷰 스터디",
            tags: ["STUDY", "WORKBOOK"],
            startTime: "19:30:00",
            endTime: "21:30:00",
            sheetId: 1004,
            recordId: 1004,
            status: .pendingApproval,
            statusDisplay: "승인 대기",
            locationVerified: true
        ),
        AvailableAttendanceSchedule(
            scheduleId: 1005,
            scheduleName: "정규 세션 10주차 (UIKit 심화)",
            tags: ["STUDY", "UX"],
            startTime: "19:00:00",
            endTime: "21:00:00",
            sheetId: 1005,
            recordId: nil,
            status: .beforeAttendance,
            statusDisplay: "출석 전",
            locationVerified: false
        ),
        AvailableAttendanceSchedule(
            scheduleId: 1006,
            scheduleName: "공통 해커톤 중간 점검",
            tags: ["HACKATHON", "PROJECT"],
            startTime: "20:00:00",
            endTime: "22:00:00",
            sheetId: 1006,
            recordId: nil,
            status: .beforeAttendance,
            statusDisplay: "출석 전",
            locationVerified: false
        )
    ]

    static let myAttendanceHistory: [AttendanceHistoryItem] = {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ko_KR")
        func date(_ dayOffset: Int) -> String {
            formatter.string(from: Calendar.current.date(byAdding: .day, value: dayOffset, to: now) ?? now)
        }

        return [
            AttendanceHistoryItem(
                attendanceId: 1001,
                scheduleId: 1001,
                scheduleName: "iOS 파트 정규 세션 OT",
                tags: ["SEMINAR", "COMMON"],
                scheduledDate: date(-12),
                startTime: "19:00:00",
                endTime: "21:00:00",
                status: .present,
                statusDisplay: "출석"
            ),
            AttendanceHistoryItem(
                attendanceId: 1002,
                scheduleId: 1002,
                scheduleName: "공통 해커톤 기획 회의",
                tags: ["HACKATHON", "PM"],
                scheduledDate: date(-11),
                startTime: "18:30",
                endTime: "20:30",
                status: .late,
                statusDisplay: "지각"
            ),
            AttendanceHistoryItem(
                attendanceId: 1003,
                scheduleId: 1003,
                scheduleName: "지부 연합 네트워킹 데이",
                tags: ["NETWORK", "EVENT"],
                scheduledDate: date(-6),
                startTime: "14:00:00",
                endTime: "16:30:00",
                status: .absent,
                statusDisplay: "결석"
            ),
            AttendanceHistoryItem(
                attendanceId: 1004,
                scheduleId: 1004,
                scheduleName: "iOS 파트 코드리뷰 스터디",
                tags: ["STUDY", "WORKBOOK"],
                scheduledDate: date(-2),
                startTime: "19:30:00",
                endTime: "21:30:00",
                status: .pendingApproval,
                statusDisplay: "승인 대기"
            ),
            AttendanceHistoryItem(
                attendanceId: 1005,
                scheduleId: 1005,
                scheduleName: "정규 세션 10주차 (UIKit 심화)",
                tags: ["STUDY", "UX"],
                scheduledDate: date(0),
                startTime: "19:00:00",
                endTime: "21:00:00",
                status: .beforeAttendance,
                statusDisplay: "출석 전"
            ),
            AttendanceHistoryItem(
                attendanceId: 1006,
                scheduleId: 1006,
                scheduleName: "공통 해커톤 중간 점검",
                tags: ["HACKATHON", "PROJECT"],
                scheduledDate: date(2),
                startTime: "20:00:00",
                endTime: "22:00:00",
                status: .beforeAttendance,
                statusDisplay: "출석 전"
            )
        ]
    }()

    static let studyMembersAllWeeks: [StudyMemberItem] = {
        var members = StudyMemberItem.preview
        let bestWorkbookMemberIDs: Set<Int> = [2, 11, 21, 31, 41, 3]

        for index in members.indices {
            let memberNo = Int(
                members[index].serverID.replacingOccurrences(
                    of: "member_",
                    with: ""
                )
            ) ?? 0

            let isBestWeek = members[index].week == (memberNo % 3) + 1
            let isBestMember = bestWorkbookMemberIDs.contains(memberNo)
            members[index].isBestWorkbook = isBestMember && isBestWeek
        }

        return members
    }()

    static func studyMembersByWeek(_ week: Int) -> [StudyMemberItem] {
        studyMembersAllWeeks.filter { $0.week == week }
    }

    static var studyMembersByCurrentWeek: [StudyMemberItem] {
        studyMembersByWeek(1)
    }
}
#endif
