//
//  NoticeReadStatusDTO.swift
//  AppProduct
//
//  Created by 이예지 on 2/14/26.
//

import Foundation

// MARK: - 공지 열람 통계 DTO

/// 공지 열람 통계 응답 DTO
struct NoticeReadStaticsDTO: Codable {
    let totalCount: String
    let readCount: String
    let unreadCount: String
    let readRate: String

    private enum CodingKeys: String, CodingKey {
        case totalCount
        case readCount
        case unreadCount
        case readRate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.totalCount = container.decodeFlexibleString(forKey: .totalCount)
        self.readCount = container.decodeFlexibleString(forKey: .readCount)
        self.unreadCount = container.decodeFlexibleString(forKey: .unreadCount)
        self.readRate = container.decodeFlexibleString(forKey: .readRate)
    }
}

// MARK: - 공지 열람 현황 상세 DTO

/// 공지 열람 현황 사용자 정보 DTO
struct NoticeReadStatusUserDTO: Codable {
    let challengerId: String
    let name: String
    let profileImageUrl: String?
    let part: String
    let schoolId: String
    let schoolName: String
    let chapterId: String
    let chapterName: String

    private enum CodingKeys: String, CodingKey {
        case challengerId
        case name
        case profileImageUrl
        case part
        case schoolId
        case schoolName
        case chapterId
        case chapterName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.challengerId = container.decodeFlexibleString(forKey: .challengerId)
        self.name = try container.decode(String.self, forKey: .name)
        self.profileImageUrl = try? container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        self.part = try container.decode(String.self, forKey: .part)
        self.schoolId = container.decodeFlexibleString(forKey: .schoolId)
        self.schoolName = try container.decode(String.self, forKey: .schoolName)
        self.chapterId = container.decodeFlexibleString(forKey: .chapterId)
        self.chapterName = try container.decode(String.self, forKey: .chapterName)
    }
}

/// 공지 열람 현황 응답 DTO (Cursor 기반 페이징)
struct NoticeReadStatusResponseDTO: Codable {
    let content: [NoticeReadStatusUserDTO]
    let nextCursor: String
    let hasNext: Bool

    private enum CodingKeys: String, CodingKey {
        case content
        case nextCursor
        case hasNext
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.content = try container.decode([NoticeReadStatusUserDTO].self, forKey: .content)
        self.nextCursor = container.decodeFlexibleOptionalString(forKey: .nextCursor) ?? ""
        self.hasNext = try container.decode(Bool.self, forKey: .hasNext)
    }
}

// MARK: - toDomain 변환

extension NoticeReadStatusUserDTO {
    /// DTO → ReadStatusUser 도메인 모델 변환
    /// - Parameter isRead: 읽음/미읽음 상태 (API 호출 시 status 파라미터로 결정됨)
    func toDomain(isRead: Bool) -> ReadStatusUser {
        // part String → UMCPartType enum 변환
        let userPart = UMCPartType(apiValue: part)
        
        return ReadStatusUser(
            id: challengerId,
            name: name,
            nickName: name, // TODO: 실제 닉네임 필드 추가되면 수정
            part: userPart?.name ?? "알 수 없음",
            branch: chapterName,
            campus: schoolName,
            profileImageURL: profileImageUrl,
            isRead: isRead
        )
    }
}

// MARK: - Flexible Decoding Helpers

private extension KeyedDecodingContainer {
    /// String, Int, Double 타입 중 하나로 디코딩하여 String으로 반환 (실패 시 빈 문자열)
    func decodeFlexibleString(forKey key: Key) -> String {
        if let value = try? decode(String.self, forKey: key) {
            return value
        }
        if let value = try? decode(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? decode(Double.self, forKey: key) {
            return String(value)
        }
        return ""
    }

    /// String, Int, Double 타입 중 하나로 디코딩하여 Optional String으로 반환
    func decodeFlexibleOptionalString(forKey key: Key) -> String? {
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return value
        }
        if let value = try? decode(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? decode(Double.self, forKey: key) {
            return String(value)
        }
        return nil
    }
}
