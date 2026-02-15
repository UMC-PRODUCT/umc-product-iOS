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
    let totalCount: Int
    let readCount: Int
    let unreadCount: Int
    let readRate: Double
}

// MARK: - 공지 열람 현황 상세 DTO

/// 공지 열람 현황 사용자 정보 DTO
struct NoticeReadStatusUserDTO: Codable {
    let challengerId: Int
    let name: String
    let profileImageUrl: String?
    let part: String
    let schoolId: Int
    let schoolName: String
    let chapterId: Int
    let chapterName: String
}

/// 공지 열람 현황 응답 DTO (Cursor 기반 페이징)
struct NoticeReadStatusResponseDTO: Codable {
    let content: [NoticeReadStatusUserDTO]
    let nextCursor: Int?
    let hasNext: Bool
}

// MARK: - toDomain 변환

extension NoticeReadStatusUserDTO {
    /// DTO → ReadStatusUser 도메인 모델 변환
    /// - Parameter isRead: 읽음/미읽음 상태 (API 호출 시 status 파라미터로 결정됨)
    func toDomain(isRead: Bool) -> ReadStatusUser {
        // part String → UMCPartType enum 변환
        let userPart = UMCPartType(apiValue: part)
        
        return ReadStatusUser(
            id: String(challengerId),
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
