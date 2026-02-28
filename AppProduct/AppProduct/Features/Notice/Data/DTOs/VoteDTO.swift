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
    let noticeVoteId: String
    let voteId: String

    private enum CodingKeys: String, CodingKey {
        case noticeVoteId
        case voteId
    }

    /// noticeVoteId, voteId가 String 또는 Int로 올 수 있어 유연하게 디코딩
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let value = try? container.decode(String.self, forKey: .noticeVoteId) {
            self.noticeVoteId = value
        } else if let value = try? container.decode(Int.self, forKey: .noticeVoteId) {
            self.noticeVoteId = String(value)
        } else {
            self.noticeVoteId = ""
        }

        if let value = try? container.decode(String.self, forKey: .voteId) {
            self.voteId = value
        } else if let value = try? container.decode(Int.self, forKey: .voteId) {
            self.voteId = String(value)
        } else {
            self.voteId = ""
        }
    }
}
