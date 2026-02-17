//
//  NoticeDetailDTO.swift
//  AppProduct
//
//  Created by 이예지 on 2/14/26.
//

import Foundation

// MARK: - NoticeDetailDTO

/// 공지 상세화면 DTO
struct NoticeDetailDTO: Codable {

    // MARK: - Property

    let id: String
    let title: String
    let content: String
    let shouldSendNotification: Bool?
    let viewCount: String
    let createdAt: String
    let updatedAt: String?
    let targetInfo: NoticeTargetInfoDTO
    let authorChallengerId: String
    let authorNickname: String?
    let authorName: String
    let authorProfileImageUrl: String?

    // 상세 추가 필드
    let vote: NoticeDetailVoteDTO?
    let images: [NoticeDetailImageDTO]
    let links: [NoticeDetailLinkDTO]
    let scope: String?
    let category: String?
    let isMustRead: Bool?
    let hasPermission: Bool?
}

// MARK: - toDomain 변환

extension NoticeDetailDTO {
    /// NoticeDetailDTO → NoticeDetail 도메인 모델 변환
    ///
    /// scope/category가 nil인 경우 targetInfo 기반으로 추론합니다.
    func toDomain() -> NoticeDetail {
        let generation = targetInfo.generationValue

        // scope 문자열이 없으면 targetInfo 기반으로 추론
        let noticeScope: NoticeScope
        if let scope {
            switch scope.uppercased() {
            case "CENTRAL": noticeScope = .central
            case "BRANCH": noticeScope = .branch
            case "CAMPUS": noticeScope = .campus
            default: noticeScope = .central
            }
        } else {
            noticeScope = targetInfo.resolvedScope
        }

        // category 문자열이 없으면 targetInfo 기반으로 추론
        let noticeCategory: NoticeCategory = {
            if let category {
                switch category.uppercased() {
                case "PART":
                    return targetInfo.resolvedCategory
                case "GENERAL":
                    return .general
                default:
                    return .general
                }
            } else {
                return targetInfo.resolvedCategory
            }
        }()

        let targetAudience = targetInfo.toTargetAudience(scope: noticeScope)

        let mappedVote = vote?.toDomain()
        let mappedImages = images.map { NoticeAttachmentImage(id: $0.id, url: $0.url) }
        let imageURLs = mappedImages.map(\.url)
        let linkURLs = links.map(\.url)

        return NoticeDetail(
            id: id,
            generation: generation,
            scope: noticeScope,
            category: noticeCategory,
            isMustRead: isMustRead ?? false,
            title: title,
            content: content,
            authorID: authorChallengerId,
            authorName: authorName,
            authorImageURL: authorProfileImageUrl,
            createdAt: createdAt.toISO8601Date(),
            updatedAt: updatedAt?.toISO8601Date(),
            targetAudience: targetAudience,
            hasPermission: hasPermission ?? false,
            images: imageURLs,
            imageItems: mappedImages,
            links: linkURLs,
            vote: mappedVote
        )
    }
}

// MARK: - String ISO8601 변환

private extension String {
    /// ISO8601 문자열을 Date로 변환
    ///
    /// fractionalSeconds 포함 포맷을 우선 시도하고, 실패 시 기본 포맷으로 재시도합니다.
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
