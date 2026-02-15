//
//  MyPageUploadDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

/// 업로드 준비 요청 DTO
struct PrepareUploadRequestDTO: Codable {
    let fileName: String
    let contentType: String
    let fileSize: Int
    let category: UploadFileCategoryDTO
}

/// 업로드 카테고리
///
/// 현재 마이페이지는 프로필 이미지만 사용합니다.
enum UploadFileCategoryDTO: String, Codable {
    case profileImage = "PROFILE_IMAGE"
}

/// 업로드 준비 응답 result DTO
struct PrepareUploadResultDTO: Codable {
    let fileId: String
    let uploadUrl: String
    let uploadMethod: String
    let headers: [String: String]?
    let expiresAt: String?
}

/// 회원 정보 수정 요청 DTO (프로필 이미지 ID)
struct UpdateMemberProfileImageRequestDTO: Codable {
    let profileImageId: String
}
