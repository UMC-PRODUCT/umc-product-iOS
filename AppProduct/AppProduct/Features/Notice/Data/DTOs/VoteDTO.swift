//
//  VoteDTO.swift
//  AppProduct
//
//  Created by 이예지 on 2/14/26.
//

import Foundation

// MARK: - 투표 추가 Request DTO

/// 공지사항 투표 추가 요청 DTO
struct AddVoteRequestDTO: Codable {
    let title: String
    let isAnonymous: Bool
    let allowMultipleChoice: Bool
    let startsAt: String
    let endsAtExclusive: String
    let options: [String]
}

// MARK: - 투표 추가 Response DTO

/// 공지사항 투표 추가 응답 DTO
struct AddVoteResponseDTO: Codable {
    let noticeVoteId: Int
    let voteId: Int
}
