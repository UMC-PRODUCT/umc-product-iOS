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
    static let mapViewModel: BaseMapViewModel = .init(container: container, info: sessionInfo, errorHandler: errorHandler)
    static let attendanceViewModel: ChallengerAttendanceViewModel = .init(
        container: container,
        errorHandler: errorHandler,
        challengeAttendanceUseCase: challengerAttendanceUseCase
    )

    static let sessionId: SessionID = SessionID(value: "iOS_6")
    static let userId: UserID = UserID(value: "River_")
    static let coordinate: Coordinate = .init(latitude: 37.582967, longitude: 127.010527)
    static let attendance: Attendance = .init(
        sessionId: sessionId,
        userId: userId,
        type: .gps,
        status: .pending,
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
#endif
