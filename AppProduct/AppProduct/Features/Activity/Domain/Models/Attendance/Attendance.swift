//
//  Attendence.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/5/26.
//

import Foundation

struct Attendence: Identifiable {
    let id: UUID
    let sessionId: SessionID
    let userId: UserID
    let type: AttendenceType
    let status: AttendenceStatus
    let locationVerification: LocationVerification?
    let reason: String?
    let createdAt: Date
}
