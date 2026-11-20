//
//  MyPageUploadDTO.swift
//  MyPageData
//
//  Created by One on 5/18/26.
//
//  마이페이지 프로필 이미지 수정 요청 DTO.
//

import Foundation

// MARK: - Profile Image

/// 회원 프로필 이미지 ID 수정 요청 DTO
///
/// `PATCH /api/v1/member` 요청 바디로 사용됩니다.
/// 업로드/confirm 단계에서 얻은 `profileImageId`를 회원 프로필에 반영합니다.
public struct UpdateMemberProfileImageRequestDTO: Encodable {
    public let profileImageId: String

    public init(profileImageId: String) {
        self.profileImageId = profileImageId
    }
}
