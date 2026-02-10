//
//  ChallengerResponseDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/10/26.
//

import Foundation

// MARK: - Challenger Detail

/// 챌린저 정보 조회 응답 DTO
///
/// `GET /api/v1/challenger/{challengerId}` 응답
///
/// - Note: `APIResponse<ChallengerResponseDTO>`로 디코딩
struct ChallengerResponseDTO: Codable {
    /// 챌린저 고유 ID
    let challengerId: Int
    /// 회원 고유 ID
    let memberId: Int
    /// 기수
    let gisu: Int
    /// 소속 파트 (PLAN, DESIGN, WEB, ANDROID, IOS, NODEJS, SPRINGBOOT)
    let part: String
    /// 상벌점 목록
    let challengerPoints: [ChallengerPointDTO]
    /// 이름
    let name: String
    /// 닉네임
    let nickname: String
    /// 이메일
    let email: String
    /// 학교 ID
    let schoolId: Int
    /// 학교명
    let schoolName: String
    /// 프로필 이미지 URL
    let profileImageLink: String?
    /// 활동 상태 (ACTIVE 등)
    let status: String
}

// MARK: - Challenger Point

/// 챌린저 상벌점 DTO
struct ChallengerPointDTO: Codable {
    /// 상벌점 고유 ID
    let id: Int
    /// 포인트 타입 (BEST_WORKBOOK 등)
    let pointType: String
    /// 점수
    let point: Double
    /// 부여 사유
    let description: String
}
