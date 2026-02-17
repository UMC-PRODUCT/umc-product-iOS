//
//  ChallengerSearchDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/12/26.
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

    private enum CodingKeys: String, CodingKey {
        case cursor
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cursor = try container.decodeIfPresent(CursorDTO<ChallengerSearchItemDTO>.self, forKey: .cursor)
            ?? CursorDTO(content: [], nextCursor: nil, hasNext: false)
    }
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

    private enum CodingKeys: String, CodingKey {
        case memberId
        case nickname
        case name
        case part
        case schoolName
        case gisu
        case profileImageUrl
    }

    init(
        memberId: Int,
        nickname: String,
        name: String,
        part: UMCPartType,
        schoolName: String,
        gisu: String,
        profileImageUrl: String?
    ) {
        self.memberId = memberId
        self.nickname = nickname
        self.name = name
        self.part = part
        self.schoolName = schoolName
        self.gisu = gisu
        self.profileImageUrl = profileImageUrl
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        memberId = try container.decodeIntFlexibleIfPresent(forKey: .memberId) ?? 0
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        part = try container.decodeIfPresent(UMCPartType.self, forKey: .part) ?? .pm
        schoolName = try container.decodeIfPresent(String.self, forKey: .schoolName) ?? ""
        gisu = try container.decodeStringFlexibleIfPresent(forKey: .gisu) ?? "0"
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
    }
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

    private enum CodingKeys: String, CodingKey {
        case content
        case nextCursor
        case hasNext
    }

    init(content: [T], nextCursor: Int?, hasNext: Bool) {
        self.content = content
        self.nextCursor = nextCursor
        self.hasNext = hasNext
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decodeIfPresent([T].self, forKey: .content) ?? []
        nextCursor = try container.decodeIntFlexibleIfPresent(forKey: .nextCursor)
        hasNext = try container.decodeIfPresent(Bool.self, forKey: .hasNext) ?? false
    }
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

private extension KeyedDecodingContainer {
    func decodeIntFlexible(forKey key: Key) throws -> Int {
        if let value = try? decode(Int.self, forKey: key) {
            return value
        }
        if let value = try? decode(String.self, forKey: key),
           let intValue = Int(value) {
            return intValue
        }
        if let value = try? decode(Double.self, forKey: key) {
            return Int(value)
        }
        throw DecodingError.typeMismatch(
            Int.self,
            DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected Int/String-number/Double for key '\(key.stringValue)'"
            )
        )
    }

    func decodeIntFlexibleIfPresent(forKey key: Key) throws -> Int? {
        if (try? decodeNil(forKey: key)) == true {
            return nil
        }
        return try? decodeIntFlexible(forKey: key)
    }

    func decodeStringFlexibleIfPresent(forKey key: Key) throws -> String? {
        if let value = try? decode(String.self, forKey: key) {
            return value
        }
        if let value = try? decode(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? decode(Double.self, forKey: key) {
            return String(Int(value))
        }
        return nil
    }
}
