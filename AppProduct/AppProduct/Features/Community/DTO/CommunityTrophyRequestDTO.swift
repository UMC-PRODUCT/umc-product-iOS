
//
//  CommunityTrophyRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/10/26.
//

import Foundation

// MARK: - Trophy List

/// 상장 목록 조회 쿼리 DTO
///
/// `GET /api/v1/trophies` 쿼리 파라미터
struct TrophyListQuery: Encodable {
    /// 주차 (Week)
    let week: Int?
    /// 학교
    let school: String?
    /// 파트
    let part: String?
    
    var toParameters: [String: Any] {
        var params: [String: Any] = [:]
        if let week = week { params["week"] = week }
        if let school = school { params["school"] = school }
        if let part = part { params["part"] = part }
        return params
    }
}

// MARK: - Create Trophy

/// 상장 생성 요청 DTO
///
/// `POST /api/v1/trophies` 요청 Body
struct CreateTrophyRequestDTO: Encodable {
    let challengerId: Int
    let week: Int
    let title: String
    let content: String
    let url: String
}
