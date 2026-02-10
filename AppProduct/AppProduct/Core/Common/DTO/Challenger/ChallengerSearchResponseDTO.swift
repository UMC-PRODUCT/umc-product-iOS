//
//  ChallengerSearchResponseDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/10/26.
//

import Foundation

// MARK: - Search Offset Response

/// 챌린저 검색 (Offset 기반) 응답 DTO
///
/// `GET /api/v1/challenger/search/offset` 응답
///
/// - Note: `APIResponse<ChallengerSearchOffsetResponseDTO>`로 디코딩
struct ChallengerSearchOffsetResponseDTO: Codable {
    /// 페이지네이션 데이터
    let page: PageDTO<ChallengerSearchItemDTO>
    /// 파트별 인원수 통계
    let partCounts: [PartCountDTO]
}

// MARK: - Search Cursor Response

/// 챌린저 검색 (Cursor 기반) 응답 DTO
///
/// `GET /api/v1/challenger/search/cursor` 응답
///
/// - Note: `APIResponse<ChallengerSearchCursorResponseDTO>`로 디코딩
struct ChallengerSearchCursorResponseDTO: Codable {
    /// 커서 페이지네이션 데이터
    let cursor: CursorDTO<ChallengerSearchItemDTO>
    /// 파트별 인원수 통계
    let partCounts: [PartCountDTO]
}

// MARK: - Search Item

/// 챌린저 검색 결과 항목
///
/// Offset/Cursor 검색 모두에서 공통으로 사용되는 항목 DTO
struct ChallengerSearchItemDTO: Codable {
    /// 챌린저 고유 ID
    let challengerId: Int
    /// 회원 고유 ID
    let memberId: Int
    /// 기수 ID
    let gisuId: Int
    /// 소속 파트
    let part: String
    /// 이름
    let name: String
    /// 닉네임
    let nickname: String
    /// 상벌점 합계
    let pointSum: Double
    /// 프로필 이미지 URL
    let profileImageLink: String?
    /// 역할 목록 (SUPER_ADMIN 등)
    let roleTypes: [String]
}

// MARK: - Part Count

/// 파트별 인원수
struct PartCountDTO: Codable {
    /// 파트명
    let part: String
    /// 인원수
    let count: Int
}
