//
//  NoticeDTO.swift
//  AppProduct
//
//  Created by 이예지 on 2/12/26.
//

import Foundation

/// 공지 리스트카드 DTO
struct NoticeDTO: Codable {
    let id: String
    let title: String
    let content: String
    let shouldSendNotification: Bool
    let viewCount: String
    let createdAt: String
    let targetInfo: TargetInfoDTO
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

extension NoticeDTO {
    /// NoticeDTO → NoticeItemModel 변환 (공지 목록용)
    func toItemModel() -> NoticeItemModel {
        let generation = targetInfo.targetGisuId
        
        // scope 결정
        let scope: NoticeScope = {
            if targetInfo.targetSchoolId != nil {
                return .campus
            } else if targetInfo.targetChapterId != nil {
                return .branch
            } else {
                return .central
            }
        }()
        
        // category 결정
        let category: NoticeCategory = {
            if let partType = targetInfo.targetParts {
                return .part(partType.toPart())
            }
            return .general
        }()
        
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

private extension String {
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

extension UMCPartType {
    /// UMCPartType → Part 도메인 모델 변환
    func toPart() -> Part {
        switch self {
        case .pm:
            return .plan
        case .design:
            return .design
        case .server(let type):
            switch type {
            case .spring:
                return .springboot
            case .node:
                return .nodejs
            }
        case .front(let type):
            switch type {
            case .web:
                return .web
            case .android:
                return .android
            case .ios:
                return .ios
            }
        }
    }
}
