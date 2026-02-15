//
//  NoticeDTO.swift
//  AppProduct
//
//  Created by 이예지 on 2/12/26.
//

import Foundation

// MARK: - Notice DTO
/// 공지 리스트카드 DTO
struct NoticeDTO: Codable {
    let id: String
    let title: String
    let content: String
    let shouldSendNotification: Bool
    let viewCount: String
    let createdAt: String
    let targetInfo: NoticeTargetInfoDTO
    let authorChallengerId: String
    let authorNickname: String
    let authorName: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case shouldSendNotification
        case viewCount
        case createdAt
        case targetInfo
        case authorChallengerId
        case authorNickname
        case authorName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        func decodeStringFlexible(_ key: CodingKeys) throws -> String {
            if let stringValue = try? container.decode(String.self, forKey: key) {
                return stringValue
            }
            if let intValue = try? container.decode(Int.self, forKey: key) {
                return String(intValue)
            }
            if let doubleValue = try? container.decode(Double.self, forKey: key) {
                return String(Int(doubleValue))
            }
            throw DecodingError.typeMismatch(
                String.self,
                DecodingError.Context(
                    codingPath: container.codingPath + [key],
                    debugDescription: "Expected String/Int/Double for key '\(key.stringValue)'"
                )
            )
        }

        self.id = try decodeStringFlexible(.id)
        self.title = try container.decode(String.self, forKey: .title)
        self.content = try container.decode(String.self, forKey: .content)
        self.shouldSendNotification = try container.decode(Bool.self, forKey: .shouldSendNotification)
        self.viewCount = try decodeStringFlexible(.viewCount)
        self.createdAt = try container.decode(String.self, forKey: .createdAt)
        self.authorChallengerId = try decodeStringFlexible(.authorChallengerId)
        self.authorNickname = try container.decode(String.self, forKey: .authorNickname)
        self.authorName = try container.decode(String.self, forKey: .authorName)

        self.targetInfo = try container.decode(TargetInfoDTO.self, forKey: .targetInfo)
    }
}

// MARK: - Mapping
extension NoticeDTO {
    /// NoticeDTO → NoticeItemModel 변환 (공지 목록용)
    func toItemModel() -> NoticeItemModel {
        let generation = targetInfo.generationValue
        let scope = targetInfo.resolvedScope
        let category = targetInfo.resolvedCategory
        
        return NoticeItemModel(
            noticeId: id,
            generation: generation,
            scope: scope,
            category: category,
            mustRead: false,
            isAlert: shouldSendNotification,
            date: createdAt.toISO8601Date(),
            title: title,
            content: content,
            writer: authorName,  // 또는 authorNickname
            links: [],  // 기본 조회에는 없음
            images: [],  // 기본 조회에는 없음
            vote: nil,
            viewCount: Int(viewCount) ?? 0
        )
    }
}

// MARK: - TargetInfo DTO
/// 공지 목록/검색 응답용 targetInfo DTO
///
/// 숫자 필드는 서버 스펙에 맞춰 String으로 처리합니다.
struct NoticeTargetInfoDTO: Codable {
    let targetGisuId: String
    let targetChapterId: String?
    let targetSchoolId: String?
    let targetParts: [UMCPartType]?
}

// MARK: - Helper
private extension String {
    /// ISO8601 문자열을 Date로 변환합니다.
    /// - Note: 소수점 초 포함/미포함 포맷을 모두 지원합니다.
    func toISO8601Date() -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let parsed = formatter.date(from: self) {
            return parsed
        }

        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: self) ?? Date()
    }
}
