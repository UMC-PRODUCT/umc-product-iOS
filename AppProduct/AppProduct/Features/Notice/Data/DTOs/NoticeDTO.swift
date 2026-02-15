//
//  NoticeDTO.swift
//  AppProduct
//
//  Created by 이예지 on 2/12/26.
//

import Foundation

/// 공지 리스트카드 DTO
struct NoticeDTO: Codable {
    let id: Int
    let title: String
    let content: String
    let shouldSendNotification: Bool
    let viewCount: Int
    let createdAt: Date
    let targetInfo: [TargetInfoDTO]
    let authorChallengerId: Int
    let authorNickname: String
    let authorName: String
}

extension NoticeDTO {
    /// NoticeDTO → NoticeItemModel 변환 (공지 목록용)
    func toItemModel() -> NoticeItemModel {
        // targetInfo에서 첫 번째 대상 정보 추출
        let firstTarget = targetInfo.first
        
        // generation 추출
        let generation = firstTarget?.targetGisuId ?? 0
        
        // scope 결정
        let scope: NoticeScope = {
            if let target = firstTarget {
                if target.targetSchoolId != nil {
                    return .campus
                } else if target.targetChapterId != nil {
                    return .branch
                } else {
                    return .central
                }
            }
            return .central
        }()
        
        // category 결정
        let category: NoticeCategory = {
            if let partType = firstTarget?.targetParts {
                return .part(partType.toPart())
            }
            return .general
        }()
        
        // ISO8601DateFormatter
        let dateFormatter = ISO8601DateFormatter()
        
        return NoticeItemModel(
            generation: generation,
            scope: scope,
            category: category,
            mustRead: false,
            isAlert: shouldSendNotification,
            date: dateFormatter.date(from: String(describing: createdAt)) ?? Date(),
            title: title,
            content: content,
            writer: authorName,  // 또는 authorNickname
            links: [],  // 기본 조회에는 없음
            images: [],  // 기본 조회에는 없음
            vote: nil,
            viewCount: viewCount
        )
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
