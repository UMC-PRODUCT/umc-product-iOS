//
//  MyPageUploadDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

// MARK: - Profile Image

/// 회원 정보 수정 요청 DTO (프로필 이미지 ID)
struct UpdateMemberProfileImageRequestDTO: Codable {
    let profileImageId: String
}

// MARK: - Profile Links

/// 회원 정보 수정 요청 DTO (소셜/포트폴리오 링크)
///
/// `PATCH /api/v1/member/profile/links` 요청 바디로 사용됩니다.
struct UpdateMemberProfileLinksRequestDTO: Codable {
    /// 수정할 링크 항목 배열
    let links: [UpdateMemberProfileLinkRequestDTO]
}

/// 링크 수정 요청 항목 DTO
struct UpdateMemberProfileLinkRequestDTO: Codable {
    /// 링크 타입 (예: "GITHUB", "LINKEDIN", "BLOG")
    let type: String
    /// 링크 URL 문자열
    let link: String
}
