//
//  AttendancePreviewData.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/15/26.
//

import Foundation
import SwiftUI

#if DEBUG
struct AttendancePreviewData {
    static let container = DIContainer.configured()
    static let errorHandler = ErrorHandler()
    static let challengerAttendanceUseCase = ChallengerAttendanceUseCase(repository: MockAttendanceRepository())
    static let mockUseCase = MockChallengerAttendanceUseCase()
    static let mapViewModel: BaseMapViewModel = .init(container: container, info: sessionInfo, errorHandler: errorHandler)
    static let attendanceViewModel: ChallengerAttendanceViewModel = .init(
        container: container,
        errorHandler: errorHandler,
        challengeAttendanceUseCase: mockUseCase  // 시뮬레이터 테스트용 Mock 사용
    )

    static let sessionId: SessionID = SessionID(value: "iOS_6")
    static let userId: UserID = UserID(value: "River_")
    static let coordinate: Coordinate = .init(latitude: 37.582967, longitude: 127.010527)
    static let attendance: Attendance = .init(
        sessionId: sessionId,
        userId: userId,
        type: .gps,
        status: .beforeAttendance,
        locationVerification: .init(
            isVerified: true,
            coordinate: coordinate,
            address: .init(
                fullAddress: "한성대학교", city: "서울시", district: "성북구"),
            verifiedAt: .now),
        reason: nil)

    static let sessionInfo: SessionInfo = .init(
        sessionId: SessionID(value: "iOS_6"),
        icon: .Activity.profile, title: "Alamofire 파헤치기",
        week: 6, startTime: Date.now, endTime: Date.now + 100,
        location: .init(latitude: 37.582967, longitude: 127.010527))

    static let session: Session = .init(info: sessionInfo, initialAttendance: attendance)

    // MARK: - State-specific Sessions

    /// 출석 전 상태 세션 (버튼 활성화)
    static var beforeAttendanceSession: Session {
        let info = SessionInfo(
            sessionId: SessionID(value: "iOS_before"),
            icon: .Activity.profile,
            title: "출석 전 테스트",
            week: 7,
            startTime: Date.now,
            endTime: Date.now + 7200,
            location: coordinate
        )
        return Session(info: info, initialAttendance: nil)
    }

    /// 승인 대기 상태 세션
    static var pendingApprovalSession: Session {
        let info = SessionInfo(
            sessionId: SessionID(value: "iOS_pending_approval"),
            icon: .Activity.profile,
            title: "승인 대기 테스트",
            week: 8,
            startTime: Date.now.addingTimeInterval(-3600),
            endTime: Date.now + 3600,
            location: coordinate
        )
        let session = Session(
            info: info,
            initialAttendance: .init(
                sessionId: info.sessionId,
                userId: userId,
                type: .gps,
                status: .beforeAttendance,
                locationVerification: .init(
                    isVerified: true,
                    coordinate: coordinate,
                    address: .init(fullAddress: "한성대학교", city: "서울시", district: "성북구"),
                    verifiedAt: .now
                ),
                reason: nil
            )
        )
        // 제출 완료 상태로 설정하면 pendingApproval 상태가 됨
        session.markSubmitted()
        return session
    }

    // MARK: - Multiple Sessions Mock

    static let sessions: [Session] = [
        .init(
            info: .init(
                sessionId: SessionID(value: "iOS_1"),
                icon: .Activity.profile,
                title: "Swift 기초 문법",
                week: 1,
                startTime: Date.now.addingTimeInterval(-86400 * 35),
                endTime: Date.now.addingTimeInterval(-86400 * 35 + 7200),
                location: .init(latitude: 37.582967, longitude: 127.010527)
            ),
            initialAttendance: .init(
                sessionId: SessionID(value: "iOS_1"),
                userId: userId,
                type: .gps,
                status: .present,
                locationVerification: nil,
                reason: nil
            )
        ),
        .init(
            info: .init(
                sessionId: SessionID(value: "iOS_2"),
                icon: .Activity.profile,
                title: "SwiftUI 레이아웃",
                week: 2,
                startTime: Date.now.addingTimeInterval(-86400 * 28),
                endTime: Date.now.addingTimeInterval(-86400 * 28 + 7200),
                location: .init(latitude: 37.582967, longitude: 127.010527)
            ),
            initialAttendance: .init(
                sessionId: SessionID(value: "iOS_2"),
                userId: userId,
                type: .gps,
                status: .present,
                locationVerification: nil,
                reason: nil
            )
        ),
        .init(
            info: .init(
                sessionId: SessionID(value: "iOS_3"),
                icon: .Activity.profile,
                title: "MVVM 아키텍처",
                week: 3,
                startTime: Date.now.addingTimeInterval(-86400 * 21),
                endTime: Date.now.addingTimeInterval(-86400 * 21 + 7200),
                location: .init(latitude: 37.582967, longitude: 127.010527)
            ),
            initialAttendance: .init(
                sessionId: SessionID(value: "iOS_3"),
                userId: userId,
                type: .gps,
                status: .late,
                locationVerification: nil,
                reason: nil
            )
        ),
        .init(
            info: .init(
                sessionId: SessionID(value: "iOS_4"),
                icon: .Activity.profile,
                title: "네트워킹 기초",
                week: 4,
                startTime: Date.now.addingTimeInterval(-86400 * 14),
                endTime: Date.now.addingTimeInterval(-86400 * 14 + 7200),
                location: .init(latitude: 37.582967, longitude: 127.010527)
            ),
            initialAttendance: .init(
                sessionId: SessionID(value: "iOS_4"),
                userId: userId,
                type: .gps,
                status: .absent,
                locationVerification: nil,
                reason: nil
            )
        ),
        .init(
            info: .init(
                sessionId: SessionID(value: "iOS_5"),
                icon: .Activity.profile,
                title: "Combine 입문",
                week: 5,
                startTime: Date.now.addingTimeInterval(-86400 * 7),
                endTime: Date.now.addingTimeInterval(-86400 * 7 + 7200),
                location: .init(latitude: 37.582967, longitude: 127.010527)
            ),
            initialAttendance: .init(
                sessionId: SessionID(value: "iOS_5"),
                userId: userId,
                type: .gps,
                status: .present,
                locationVerification: nil,
                reason: nil
            )
        ),
        session  // 기존 6주차 세션
    ]

    /// 모든 상태를 포함하는 세션 목록 (테스트용)
    static var allStatusSessions: [Session] {
        var list = sessions
        list.append(pendingApprovalSession)
        return list
    }

    /// 출석 가능한 세션이 여러 개인 테스트용 목록
    static var multipleAvailableSessions: [Session] {
        [
            // 출석 전 세션 1
            .init(
                info: .init(
                    sessionId: SessionID(value: "iOS_available_1"),
                    icon: .Activity.profile,
                    title: "Swift Concurrency",
                    week: 7,
                    startTime: Date.now,
                    endTime: Date.now + 7200,
                    location: coordinate
                ),
                initialAttendance: nil
            ),
            // 출석 전 세션 2
            .init(
                info: .init(
                    sessionId: SessionID(value: "iOS_available_2"),
                    icon: .Activity.profile,
                    title: "Core Data 기초",
                    week: 8,
                    startTime: Date.now + 86400,
                    endTime: Date.now + 86400 + 7200,
                    location: coordinate
                ),
                initialAttendance: nil
            ),
            // 승인 대기 세션
            pendingApprovalSession,
            // 완료된 세션 (나의 출석 현황에 표시)
            .init(
                info: .init(
                    sessionId: SessionID(value: "iOS_completed"),
                    icon: .Activity.profile,
                    title: "지난 세션",
                    week: 6,
                    startTime: Date.now.addingTimeInterval(-86400 * 7),
                    endTime: Date.now.addingTimeInterval(-86400 * 7 + 7200),
                    location: coordinate
                ),
                initialAttendance: .init(
                    sessionId: SessionID(value: "iOS_completed"),
                    userId: userId,
                    type: .gps,
                    status: .present,
                    locationVerification: nil,
                    reason: nil
                )
            )
        ]
    }

    // MARK: - Simulator Test Sessions

    /// 시뮬레이터 테스트용 세션 목록 (상태 변경 가능)
    static var testSessions: [Session] {
        [
            // 출석 전 세션
            .init(
                info: .init(
                    sessionId: SessionID(value: "test_1"),
                    icon: .Activity.profile,
                    title: "Swift Concurrency",
                    week: 7,
                    startTime: Date.now,
                    endTime: Date.now + 7200,
                    location: coordinate
                ),
                initialAttendance: nil
            ),
            // 출석 전 세션 2
            .init(
                info: .init(
                    sessionId: SessionID(value: "test_2"),
                    icon: .Activity.profile,
                    title: "Core Data 기초",
                    week: 8,
                    startTime: Date.now + 86400,
                    endTime: Date.now + 86400 + 7200,
                    location: coordinate
                ),
                initialAttendance: nil
            ),
            // 완료된 세션들
            .init(
                info: .init(
                    sessionId: SessionID(value: "test_3"),
                    icon: .Activity.profile,
                    title: "SwiftUI 레이아웃",
                    week: 1,
                    startTime: Date.now.addingTimeInterval(-86400 * 14),
                    endTime: Date.now.addingTimeInterval(-86400 * 14 + 7200),
                    location: coordinate
                ),
                initialAttendance: .init(
                    sessionId: SessionID(value: "test_3"),
                    userId: userId,
                    type: .gps,
                    status: .present,
                    locationVerification: nil,
                    reason: nil
                )
            ),
            .init(
                info: .init(
                    sessionId: SessionID(value: "test_4"),
                    icon: .Activity.profile,
                    title: "MVVM 아키텍처",
                    week: 2,
                    startTime: Date.now.addingTimeInterval(-86400 * 7),
                    endTime: Date.now.addingTimeInterval(-86400 * 7 + 7200),
                    location: coordinate
                ),
                initialAttendance: .init(
                    sessionId: SessionID(value: "test_4"),
                    userId: userId,
                    type: .gps,
                    status: .late,
                    locationVerification: nil,
                    reason: nil
                )
            )
        ]
    }
}

// MARK: - Attendance Status Preview

struct AttendanceStatusPreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("출석 상태별 테스트")
                    .appFont(.title2Emphasis, color: .grey900)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(AttendanceStatus.allCases, id: \.self) { status in
                    HStack {
                        Text(status.displayText)
                            .appFont(.body, color: status.fontColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(status.backgroundColor, in: Capsule())

                        Spacer()

                        Text(status.rawValue)
                            .appFont(.caption1, color: .grey600)
                    }
                    .padding()
                    .background(.white, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .background(Color.grey100)
    }
}

struct AttendanceTestView: View {
    @Binding var show: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Button("출석 화면 열기") {
                show.toggle()
            }
            .buttonStyle(.borderedProminent)
            
            Divider()
        }
        .task {
            LocationManager.shared.requestAuthorization()
        }
    }
}

#Preview("Attendance Status Badges") {
    AttendanceStatusPreview()
}

#Preview("Pending Approval View") {
    ZStack {
        Color.grey100.ignoresSafeArea()
        PendingApprovalView()
            .padding()
    }
}
#endif
