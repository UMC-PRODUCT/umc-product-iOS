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
    static let container = DIContainer()
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
