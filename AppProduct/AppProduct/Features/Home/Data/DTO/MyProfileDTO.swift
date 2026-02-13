//
//  MyProfileDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/11/26.
//

import Foundation

/// 내 프로필 조회 Response DTO
///
/// `GET /api/v1/member/me`
///
/// 홈 화면 기수 카드, 역할 정보, AppStorage 저장에 사용됩니다.
struct MyProfileResponseDTO: Codable {

    // MARK: - Property

    /// 멤버 고유 ID
    let id: Int
    /// 이름
    let name: String
    /// 닉네임
    let nickname: String
    /// 이메일
    let email: String
    /// 학교 ID
    let schoolId: Int
    /// 학교 이름
    let schoolName: String
    /// 프로필 이미지 URL
    let profileImageLink: String
    /// 멤버 상태 (ACTIVE / INACTIVE / WITHDRAWN)
    let status: MemberStatus
    /// 기수별 역할 목록
    let roles: [RoleDTO]
}

// MARK: - RoleDTO

/// 기수별 역할 정보 DTO
struct RoleDTO: Codable {
    /// 역할 고유 ID
    let id: Int
    /// 챌린저 ID
    let challengerId: Int
    /// 역할 타입 (CHALLENGER / SCHOOL_PART_LEADER 등)
    let roleType: ManagementTeam
    /// 소속 조직 타입 (CENTRAL / CHAPTER / SCHOOL)
    let organizationType: OrganizationType
    /// 소속 조직 ID
    let organizationId: Int
    /// 담당 파트 (파트장만 해당, API 문자열: "IOS", "WEB" 등)
    let responsiblePart: String?
    /// 기수 번호 (예: 9, 10)
    let gisu: Int
    /// 서버 기수 식별 ID
    let gisuId: Int
}

// MARK: - MemberStatus

/// 멤버 활동 상태
enum MemberStatus: String, Codable {
    /// 활동 중
    case active = "ACTIVE"
    /// 비활성
    case inactive = "INACTIVE"
    /// 탈퇴
    case withdrawn = "WITHDRAWN"
}

// MARK: - toDomain

extension MyProfileResponseDTO {
    /// 기수당 활동일 수
    private static let daysPerGisu = 165

    /// DTO → [SeasonType] 변환 (홈 화면 기수 카드용)
    ///
    /// - ACTIVE: 현재(최신) 기수는 진행 중이므로 누적 활동일 계산에서 제외
    /// - INACTIVE/WITHDRAWN: 모든 기수가 완료된 것으로 간주
    func toSeasonTypes() -> [SeasonType] {
        let gisuIds = Set(roles.map(\.gisu)).sorted()

        let completedCount: Int
        if status == .active, gisuIds.count > 1 {
            completedCount = gisuIds.count - 1
        } else if status == .active {
            completedCount = 0
        } else {
            completedCount = gisuIds.count
        }

        return [
            .days(completedCount * Self.daysPerGisu),
            .gens(gisuIds)
        ]
    }

    /// DTO → 최고 권한 역할 반환
    func highestRole() -> ManagementTeam {
        roles.map(\.roleType).max() ?? .challenger
    }

    /// DTO → HomeProfileResult 변환 (기수 카드 + 역할 정보)
    func toHomeProfileResult() -> HomeProfileResult {
        let challengerRoles = roles.map {
            ChallengerRole(
                challengerId: $0.challengerId,
                gisu: $0.gisu,
                gisuId: $0.gisuId,
                roleType: $0.roleType,
                responsiblePart: $0.responsiblePart.flatMap { UMCPartType(apiValue: $0) },
                organizationType: $0.organizationType,
                organizationId: $0.organizationId
            )
        }
        return HomeProfileResult(
            memberId: id,
            schoolId: schoolId,
            seasonTypes: toSeasonTypes(),
            roles: challengerRoles
        )
    }
}
