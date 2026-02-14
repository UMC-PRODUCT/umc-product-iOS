//
//  MyPageRepositoryProtocol.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

/// MyPage 데이터 접근 Repository Protocol
protocol MyPageRepositoryProtocol: Sendable {

    /// 내 프로필 조회
    func fetchMyProfile() async throws -> ProfileData

    /// 프로필 이미지를 업로드하고 회원 프로필에 반영합니다.
    ///
    /// 내부 흐름:
    /// prepare-upload -> signed URL 업로드 -> confirm -> member patch
    func updateProfileImage(
        imageData: Data,
        fileName: String,
        contentType: String
    ) async throws -> ProfileData
}
