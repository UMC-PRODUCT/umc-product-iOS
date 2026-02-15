//
//  MyPageUploadDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

/// 회원 정보 수정 요청 DTO (프로필 이미지 ID)
struct UpdateMemberProfileImageRequestDTO: Codable {
    let profileImageId: String
}
