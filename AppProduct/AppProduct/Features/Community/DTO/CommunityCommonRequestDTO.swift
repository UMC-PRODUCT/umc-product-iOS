
//
//  CommunityCommonRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/10/26.
//

import Foundation

// MARK: - Generic Queries

/// 챌린저 ID 쿼리 DTO (재사용)
struct ChallengerIdQuery: Encodable {
    let challengerId: Int
    
    var toParameters: [String: Any] {
        ["challengerId": challengerId]
    }
}
