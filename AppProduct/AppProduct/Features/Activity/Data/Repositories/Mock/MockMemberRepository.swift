//
//  MockMemberRepository.swift
//  AppProduct
//
//  Created by 김미주 on 2/5/26.
//

import Foundation

final class MockMemberRepository: MemberRepositoryProtocol {
    // MARK: - Function
    func fetchMembers() async throws -> [MemberManagementItem] {
        return [
            // 이예지 (Part Leader) - 완벽한 출석
            .init(
                profile: nil,
                name: "이예지",
                generation: "9기",
                position: "Part Leader",
                part: .front(type: .ios),
                penalty: 0,
                badge: false,
                managementTeam: .schoolPartLeader,
                attendanceRecords: MockAttendanceRecords.perfect
            ),
            
            // 이예지 (President) - 완벽한 출석
            .init(
                profile: nil,
                name: "이예지",
                generation: "9기",
                position: "Part Leader",
                part: .front(type: .ios),
                penalty: 0,
                badge: false,
                managementTeam: .schoolPartLeader,
                attendanceRecords: MockAttendanceRecords.perfect
            ),
            
            // 김철수 - 보통 출석 (몇 번 지각)
            .init(
                profile: nil,
                name: "김철수",
                generation: "9기",
                position: "Member",
                part: .front(type: .android),
                penalty: 1,
                badge: false,
                managementTeam: .challenger,
                attendanceRecords: MockAttendanceRecords.average
            ),
            
            // 박영희 - 좋은 출석
            .init(
                profile: nil,
                name: "박영희",
                generation: "9기",
                position: "Member",
                part: .server(type: .spring),
                penalty: 0,
                badge: false,
                managementTeam: .challenger,
                attendanceRecords: MockAttendanceRecords.good
            ),
            
            // 최민수 - 불성실한 출석 (결석 많음)
            .init(
                profile: nil,
                name: "최민수",
                generation: "9기",
                position: "Member",
                part: .front(type: .web),
                penalty: 2,
                badge: false,
                managementTeam: .challenger,
                attendanceRecords: MockAttendanceRecords.poor
            ),
            
            // 정다은 - 좋은 출석
            .init(
                profile: nil,
                name: "정다은",
                generation: "9기",
                position: "Member",
                part: .design,
                penalty: 0,
                badge: false,
                managementTeam: .challenger,
                attendanceRecords: MockAttendanceRecords.good
            ),
            
            // 강호진 - 보통 출석
            .init(
                profile: nil,
                name: "강호진",
                generation: "9기",
                position: "Member",
                part: .pm,
                penalty: 1,
                badge: false,
                managementTeam: .challenger,
                attendanceRecords: MockAttendanceRecords.average
            ),
            
            // 신입생 - 출석 기록 없음
            .init(
                profile: nil,
                name: "이신입",
                generation: "9기",
                position: "Member",
                part: .front(type: .ios),
                penalty: 0,
                badge: false,
                managementTeam: .challenger,
                attendanceRecords: []
            ),
        ]
    }
}

// MARK: - Mock Attendance Records

private enum MockAttendanceRecords {
    /// 완벽한 출석 (7/7 출석)
    static let perfect: [MemberAttendanceRecord] = [
        MemberAttendanceRecord(
            sessionTitle: "OT 및 Git 기초",
            week: 1,
            status: .present
        ),
        MemberAttendanceRecord(
            sessionTitle: "iOS SwiftUI 기초",
            week: 2,
            status: .present
        ),
        MemberAttendanceRecord(
            sessionTitle: "네비게이션 & 데이터 플로우",
            week: 3,
            status: .present
        ),
        MemberAttendanceRecord(
            sessionTitle: "API 통신 & 네트워킹",
            week: 4,
            status: .present
        ),
        MemberAttendanceRecord(
            sessionTitle: "상태 관리 & MVVM 패턴",
            week: 5,
            status: .present
        ),
        MemberAttendanceRecord(
            sessionTitle: "클린 아키텍처 & DI",
            week: 6,
            status: .present
        ),
        MemberAttendanceRecord(
            sessionTitle: "프로젝트 중간 발표",
            week: 7,
            status: .present
        ),
    ]
    
    /// 좋은 출석 (6/7 출석, 1번 지각)
    static let good: [MemberAttendanceRecord] = [
        MemberAttendanceRecord(
            sessionTitle: "OT 및 Git 기초",
            week: 1,
            status: .present
        ),
        MemberAttendanceRecord(
            sessionTitle: "iOS SwiftUI 기초",
            week: 2,
            status: .present
        ),
        MemberAttendanceRecord(
            sessionTitle: "네비게이션 & 데이터 플로우",
            week: 3,
            status: .late
        ),
        MemberAttendanceRecord(
            sessionTitle: "API 통신 & 네트워킹",
            week: 4,
            status: .present
        ),
        MemberAttendanceRecord(
            sessionTitle: "상태 관리 & MVVM 패턴",
            week: 5,
            status: .present
        ),
        MemberAttendanceRecord(
            sessionTitle: "클린 아키텍처 & DI",
            week: 6,
            status: .present
        ),
        MemberAttendanceRecord(
            sessionTitle: "프로젝트 중간 발표",
            week: 7,
            status: .present
        ),
    ]
    
    /// 보통 출석 (5/7 출석, 2번 지각)
    static let average: [MemberAttendanceRecord] = [
        MemberAttendanceRecord(
            sessionTitle: "OT 및 Git 기초",
            week: 1,
            status: .present
        ),
        MemberAttendanceRecord(
            sessionTitle: "iOS SwiftUI 기초",
            week: 2,
            status: .late
        ),
        MemberAttendanceRecord(
            sessionTitle: "네비게이션 & 데이터 플로우",
            week: 3,
            status: .present
        ),
        MemberAttendanceRecord(
            sessionTitle: "API 통신 & 네트워킹",
            week: 4,
            status: .present
        ),
        MemberAttendanceRecord(
            sessionTitle: "상태 관리 & MVVM 패턴",
            week: 5,
            status: .late
        ),
        MemberAttendanceRecord(
            sessionTitle: "클린 아키텍처 & DI",
            week: 6,
            status: .present
        ),
        MemberAttendanceRecord(
            sessionTitle: "프로젝트 중간 발표",
            week: 7,
            status: .present
        ),
    ]
    
    /// 불성실한 출석 (3/7 출석, 2번 지각, 2번 결석)
    static let poor: [MemberAttendanceRecord] = [
        MemberAttendanceRecord(
            sessionTitle: "OT 및 Git 기초",
            week: 1,
            status: .late
        ),
        MemberAttendanceRecord(
            sessionTitle: "iOS SwiftUI 기초",
            week: 2,
            status: .absent
        ),
        MemberAttendanceRecord(
            sessionTitle: "네비게이션 & 데이터 플로우",
            week: 3,
            status: .late
        ),
        MemberAttendanceRecord(
            sessionTitle: "API 통신 & 네트워킹",
            week: 4,
            status: .absent
        ),
        MemberAttendanceRecord(
            sessionTitle: "상태 관리 & MVVM 패턴",
            week: 5,
            status: .present
        ),
        MemberAttendanceRecord(
            sessionTitle: "클린 아키텍처 & DI",
            week: 6,
            status: .present
        ),
        MemberAttendanceRecord(
            sessionTitle: "프로젝트 중간 발표",
            week: 7,
            status: .present
        ),
    ]
}
