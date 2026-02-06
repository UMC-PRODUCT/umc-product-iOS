//
//  OperatorAttendancePreviewData.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/6/26.
//

import Foundation

#if DEBUG
/// 운영진 출석 관리 Preview 데이터
struct OperatorAttendancePreviewData {

    // MARK: - PendingMember Mock

    /// 승인 대기 멤버 목록
    static let pendingMembers: [PendingMember] = [
        PendingMember(
            serverID: "member_1",
            name: "홍길동",
            nickname: "닉네임",
            university: "중앙대학교",
            requestTime: Date.now.addingTimeInterval(-300),
            reason: "지각 사유입니다. 버스가 늦게 와서 조금 늦었습니다."
        ),
        PendingMember(
            serverID: "member_2",
            name: "김철수",
            nickname: nil,
            university: "한성대학교",
            requestTime: Date.now.addingTimeInterval(-600),
            reason: nil
        ),
        PendingMember(
            serverID: "member_3",
            name: "이영희",
            nickname: "영희짱",
            university: "서울대학교",
            requestTime: Date.now.addingTimeInterval(-900),
            reason: "교통 체증으로 인한 지각"
        )
    ]

    // MARK: - OperatorSessionAttendance Mock

    /// 세션 출석 현황 목록 (ViewModel용)
    static var sessions: [OperatorSessionAttendance] {
        let baseSessions = AttendancePreviewData.sessions

        return [
            // 진행 중 - 승인 대기 있음
            OperatorSessionAttendance(
                serverID: "session_1",
                session: baseSessions[9],  // pm_day - 진행중
                attendanceRate: 0.85,
                attendedCount: 34,
                totalCount: 40,
                pendingMembers: pendingMembers
            ),
            // 종료됨 - 모두 승인 완료
            OperatorSessionAttendance(
                serverID: "session_2",
                session: baseSessions[0],  // union_ot - 종료됨
                attendanceRate: 1.0,
                attendedCount: 40,
                totalCount: 40,
                pendingMembers: []
            ),
            // 진행전 - 미래 세션
            OperatorSessionAttendance(
                serverID: "session_3",
                session: baseSessions[10],  // iOS_8 - 30분 후 시작
                attendanceRate: 0.0,
                attendedCount: 0,
                totalCount: 40,
                pendingMembers: []
            )
        ]
    }

    /// ViewModel 초기화용 세션 목록 (API Mock)
    static func createMockSessions() -> [OperatorSessionAttendance] {
        sessions
    }
}
#endif
