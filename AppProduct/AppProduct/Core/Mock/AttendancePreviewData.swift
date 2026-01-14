//
//  AttendancePreviewData.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/15/26.
//

import Foundation

#if DEBUG
struct AttendancePreviewData {
    static let container = DIContainer()
    static let errorHandler = ErrorHandler()
    static let challengerAttendanceUseCase = ChallengerAttendanceUseCase(repository: MockAttendanceRepository())
    static let mapViewModel: BaseMapViewModel = .init(container: container, session: session, errorHandler: errorHandler)
    static let attendanceViewModel: ChallengerAttendanceViewModel = .init(
        container: container, errorHandler: errorHandler,
        challengeAttendanceUseCase: challengerAttendanceUseCase, session: session, attendance: attendance)
        
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
    
    static let session: Session = .init(
        sessionId: SessionID(value: "iOS_6"),
        icon: "", title: "Alamofire 파헤치기",
        week: 6, startTime: Date.now, endTime: Date.now + 10,
        location: .init(latitude: 37.582967, longitude: 127.010527))
}
#endif
