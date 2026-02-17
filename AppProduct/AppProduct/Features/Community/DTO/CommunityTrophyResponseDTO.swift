//
//  CommunityTrophyResponseDTO.swift
//  AppProduct
//
//  Created by 김미주 on 2/14/26.
//

import Foundation

// MARK: - Trophy List

/// 상장 목록 조회 응답 DTO
/// `GET /api/v1/trophies`
struct TrophyListResponse: Codable {
    let trophyId: Int
    let week: Int
    let challengerName: String
    let challengerProfileImage: String? // 요청
    let school: String
    let part: UMCPartType
    let title: String
    let content: String
    let url: String
}

extension TrophyListResponse {
    func toFameItem() -> CommunityFameItemModel {
        CommunityFameItemModel(
            week: week,
            university: school,
            profileImage: challengerProfileImage,
            userName: challengerName,
            part: part,
            workbookTitle: title,
            content: content
        )
    }
}
