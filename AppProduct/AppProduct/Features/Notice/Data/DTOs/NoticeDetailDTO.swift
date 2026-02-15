//
//  NoticeDetailDTO.swift
//  AppProduct
//
//  Created by 이예지 on 2/14/26.
//

import Foundation

struct NoticeDetailDTO: Codable {
    let id: Int
    let title: String
    let content: String
    let shouldSendNotification: Bool
    let viewCount: Int
    let createdAt: String
    let updatedAt: String?
    let targetInfo: [TargetInfoDTO]
    let authorChallengerId: Int
    let authorNickname: String
    let authorName: String
    let authorProfileImageUrl: String?
    
    // 추가 필드
    let images: [String]
    let links: [String]
    let scope: String  // "CENTRAL", "BRANCH", "CAMPUS"
    let category: String  // "GENERAL", "PART"
    let isMustRead: Bool
    let hasPermission: Bool
}

extension NoticeDetailDTO {
    /// NoticeDetailDTO → NoticeDetail 변환
    func toDomain() -> NoticeDetail {
        let firstTarget = targetInfo.first
        let generation = firstTarget.flatMap { Int($0.targetGisuId) } ?? 0
        
        // scope 문자열 → NoticeScope 변환
        let noticeScope: NoticeScope = {
            switch scope.uppercased() {
            case "CENTRAL":
                return .central
            case "BRANCH":
                return .branch
            case "CAMPUS":
                return .campus
            default:
                return .central
            }
        }()
        
        // category 결정 - targetInfo에서 직접 추출 ✅
        let noticeCategory: NoticeCategory = {
            switch category.uppercased() {
            case "PART":
                // targetInfo에서 targetParts 사용
                if let partType = firstTarget?.targetParts {
                    return .part(partType.toPart())
                }
                return .part(.all)
            case "GENERAL":
                return .general
            default:
                return .general
            }
        }()
        
        // parts 배열 구성
        let parts: [Part] = targetInfo.compactMap { $0.targetParts?.toPart() }
        
        // TargetAudience 구성
        let targetAudience = TargetAudience(
            generation: generation,
            scope: noticeScope,
            parts: parts,
            branches: [],
            schools: []
        )
        
        let dateFormatter = ISO8601DateFormatter()
        
        return NoticeDetail(
            id: String(id),
            generation: generation,
            scope: noticeScope,
            category: noticeCategory,
            isMustRead: isMustRead,
            title: title,
            content: content,
            authorID: String(authorChallengerId),
            authorName: authorName,
            authorImageURL: authorProfileImageUrl,
            createdAt: dateFormatter.date(from: createdAt) ?? Date(),
            updatedAt: updatedAt.flatMap { dateFormatter.date(from: $0) },
            targetAudience: targetAudience,
            hasPermission: hasPermission,
            images: images,
            links: links,
            vote: nil
        )
    }
}
