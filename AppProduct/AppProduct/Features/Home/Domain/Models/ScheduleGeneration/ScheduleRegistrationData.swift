//
//  ScheduleRegistrationData.swift
//  AppProduct
//
//  Created by euijjang97 on 1/22/26.
//

import Foundation

/// 일정 생성 시작 및 종료 날짜
struct DateRange {
    var startDate: Date
    var endDate: Date
}

struct PlaceSearchInfo: Equatable {
    var name: String
    var address: String
    var coordinate: Coordinate
}

/// 챌린저 정보 카드
struct Participant: Identifiable, Equatable {
    var id: UUID = .init()
    let challengeId: Int
    let gen: Int
    let name: String
    let nickname: String
    let schoolName: String
    let profileImage: String?
    let part: UMCPartType
}
