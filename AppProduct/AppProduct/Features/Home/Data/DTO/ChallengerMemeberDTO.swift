//
//  ChallengerMemeberDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/11/26.
//

import Foundation

struct ChallengerMemberDTO: Codable {
    let challengerId: Int
    let memberId: Int
    let gisu: Int
    let part: String
    let challengerPoints: [ChallengerPointDTO]
    let name: String
    let nickname: String
    let email: String
    let schoolId: Int
    let schoolName: String
    let profileImageLink: String
    let status: MemberStatus
}

// MARK: - ChallengerPointDTO

struct ChallengerPointDTO: Codable {
    let id: Int
    let pointType: PointType
    let point: Double
    let description: String
}

// MARK: - PointType

enum PointType: String, Codable {
    case bestWorkbook = "BEST_WORKBOOK"
    case warning = "WARNING"
    case out = "OUT"
}
