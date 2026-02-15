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
    let targetInfo: NoticeTargetInfoDTO
    let authorChallengerId: String
    let authorNickname: String
    let authorName: String
}

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

/// 공지 목록/검색 응답용 targetInfo DTO
///
/// 숫자 필드는 서버 스펙에 맞춰 String으로 처리합니다.
struct NoticeTargetInfoDTO: Codable {
    let targetGisuId: String
    let targetChapterId: String?
    let targetSchoolId: String?
    let targetParts: [UMCPartType]?
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
