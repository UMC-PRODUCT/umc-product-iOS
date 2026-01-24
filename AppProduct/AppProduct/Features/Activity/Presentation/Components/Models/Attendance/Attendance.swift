//
//  Attendance.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/5/26.
//

import Foundation

struct Attendance: Identifiable, Equatable {
    let id: UUID = .init()
    let sessionId: SessionID
    let userId: UserID
    let type: AttendanceType
    let status: AttendanceStatus
    let locationVerification: LocationVerification?
    let reason: String?
    let createdAt: Date = .now
    
    func approved(with verification: LocationVerification) -> Self {
        return copy(status: .present, locationVerification: verification)
    }
    
    func pending() -> Self {
        return copy(status: .pending)
    }
    
    func rejected(status: AttendanceStatus) -> Self {
        return copy(status: status)
    }
    
    func late(reason: String) -> Self {
        return copy(status: .late, reason: reason)
    }
    
    func absent(reason: String) -> Self {
        return copy(status: .absent, reason: reason)
    }
    
    private func copy(
        type: AttendanceType? = nil,
        status: AttendanceStatus? = nil,
        reason: String? = nil,
        locationVerification: LocationVerification? = nil
    ) -> Self {
        return .init(
            sessionId: self.sessionId,
            userId: self.userId,
            type: type ?? self.type,
            status: status ?? self.status,
            locationVerification: locationVerification ?? self.locationVerification,
            reason: reason ?? self.reason
        )
    }
}
