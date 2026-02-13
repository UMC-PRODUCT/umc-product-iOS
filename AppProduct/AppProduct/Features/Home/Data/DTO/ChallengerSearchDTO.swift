//
//  ChallengerSearchDTO.swift
//  AppProduct
//
//  Created by Claude on 2/12/26.
//

import Foundation

// MARK: - Request

/// 챌린저 전역 검색 요청 DTO
///
/// `GET /api/v1/challenger/search/global` 엔드포인트의 Query Parameter
struct ChallengerSearchRequestDTO {
    /// 이전 페이지의 마지막 챌린저 ID (첫 페이지 조회 시 nil)
    let cursor: Int?
    /// 한 페이지에 조회할 항목 수 (기본값 50, 최대 50)
    let size: Int
    /// 이름으로 부분 검색
    let name: String?
    /// 닉네임으로 부분 검색
    let nickname: String?

    init(
        cursor: Int? = nil,
        size: Int = 50,
        name: String? = nil,
        nickname: String? = nil
    ) {
        self.cursor = cursor
        self.size = size
        self.name = name
        self.nickname = nickname
    }

    /// Query Parameter Dictionary 변환
    var queryItems: [String: Any] {
        var params: [String: Any] = [
            "size": size
        ]
        if let cursor { params["cursor"] = cursor }
        if let name { params["name"] = name }
        if let nickname { params["nickname"] = nickname }
        return params
    }
}

// MARK: - Response

/// 챌린저 검색 응답 DTO (Cursor 기반 페이지네이션)
struct ChallengerSearchResponseDTO: Codable {
    let cursor: CursorDTO<ChallengerSearchItemDTO>
}

/// 챌린저 검색 결과 항목 DTO
struct ChallengerSearchItemDTO: Codable {
    let memberId: Int
    let nickname: String
    let name: String
    let part: UMCPartType
    let schoolName: String
    let gisu: String
    let profileImageUrl: String?
}

// MARK: - CursorDTO

/// Cursor 기반 페이지네이션 공용 DTO
///
/// 제네릭 타입 `T`로 다양한 목록 응답에 재사용 가능합니다.
struct CursorDTO<T: Codable>: Codable {
    /// 현재 페이지 항목 목록
    let content: [T]
    /// 다음 페이지 조회용 커서 값 (마지막 페이지 시 nil)
    let nextCursor: Int?
    /// 다음 페이지 존재 여부
    let hasNext: Bool
}

// MARK: - toDomain

extension ChallengerSearchItemDTO {
    func toChallengerInfo() -> ChallengerInfo {
        ChallengerInfo(
            memberId: memberId,
            gen: Int(gisu) ?? 0,
            name: name,
            nickname: nickname,
            schoolName: schoolName,
            profileImage: profileImageUrl,
            part: part
        )
    }
}

extension ChallengerSearchResponseDTO {
    func toChallengerInfoList() -> [ChallengerInfo] {
        cursor.content.map { $0.toChallengerInfo() }
    }
}
