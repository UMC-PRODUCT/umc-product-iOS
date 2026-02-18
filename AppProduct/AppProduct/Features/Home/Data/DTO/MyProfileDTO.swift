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
    let profileImageLink: String?
    /// 멤버 상태 (ACTIVE / INACTIVE / WITHDRAWN)
    let status: MemberStatus
    /// 기수별 역할 목록
    let roles: [RoleDTO]
    /// 챌린저 이력 목록 (기수별 포인트 포함)
    let challengerRecords: [ChallengerMemberDTO]?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case nickname
        case email
        case schoolId
        case schoolName
        case profileImageLink
        case status
        case roles
        case challengerRecords
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIntFlexibleIfPresent(forKey: .id) ?? 0
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname) ?? ""
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        schoolId = try container.decodeIntFlexibleIfPresent(forKey: .schoolId) ?? 0
        schoolName = try container.decodeIfPresent(String.self, forKey: .schoolName) ?? ""
        profileImageLink = try container.decodeIfPresent(String.self, forKey: .profileImageLink)
        status = try container.decodeIfPresent(MemberStatus.self, forKey: .status) ?? .inactive
        roles = try container.decodeIfPresent([RoleDTO].self, forKey: .roles) ?? []
        challengerRecords = try container.decodeIfPresent([ChallengerMemberDTO].self, forKey: .challengerRecords) ?? []
    }
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

    private enum CodingKeys: String, CodingKey {
        case id
        case challengerId
        case roleType
        case organizationType
        case organizationId
        case responsiblePart
        case gisu
        case gisuId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIntFlexibleIfPresent(forKey: .id) ?? 0
        challengerId = try container.decodeIntFlexibleIfPresent(forKey: .challengerId) ?? 0
        roleType = try container.decodeIfPresent(ManagementTeam.self, forKey: .roleType) ?? .challenger
        organizationType = try container.decodeIfPresent(OrganizationType.self, forKey: .organizationType) ?? .central
        organizationId = try container.decodeIntFlexibleIfPresent(forKey: .organizationId) ?? 0
        responsiblePart = try container.decodeIfPresent(String.self, forKey: .responsiblePart)
        gisu = try container.decodeIntFlexibleIfPresent(forKey: .gisu) ?? 0
        gisuId = try container.decodeIntFlexibleIfPresent(forKey: .gisuId) ?? 0
    }
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
    /// DTO → 최고 권한 역할 반환
    func highestRole() -> ManagementTeam {
        roles.map(\.roleType).max() ?? .challenger
    }

    /// DTO → HomeProfileResult 변환 (기수 카드 + 역할 정보)
    func toHomeProfileResult(seasonTypes: [SeasonType]? = nil) -> HomeProfileResult {
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

        let gisuIdByGisu = roles.reduce(into: [Int: Int]()) { partialResult, role in
            // 동일 기수 역할이 여러 개일 수 있어 안전하게 병합한다.
            if let existing = partialResult[role.gisu] {
                if existing == 0, role.gisuId != 0 {
                    partialResult[role.gisu] = role.gisuId
                }
            } else {
                partialResult[role.gisu] = role.gisuId
            }
        }
        
        let generations: [GenerationData] = (challengerRecords ?? []).compactMap { record in
            let gisuId = gisuIdByGisu[record.gisu] ?? record.gisuId
            return record.toGenerationData(gisuId: gisuId)
        }

        let latestRecord = (challengerRecords ?? [])
            .max(by: { $0.gisu < $1.gisu })

        let resolvedSeasonTypes = seasonTypes ?? [
            .days(0),
            .gens(Set(roles.map(\.gisu)).sorted())
        ]

        return HomeProfileResult(
            memberId: id,
            schoolId: schoolId,
            schoolName: schoolName,
            latestChallengerId: latestRecord?.challengerId,
            latestGisuId: latestRecord?.gisuId,
            chapterId: latestRecord?.chapterId,
            chapterName: latestRecord?.chapterName ?? "",
            part: latestRecord.flatMap { UMCPartType(apiValue: $0.part) },
            seasonTypes: resolvedSeasonTypes,
            roles: challengerRoles,
            generations: generations
        )
    }
}

private extension KeyedDecodingContainer {
    func decodeIntFlexible(forKey key: Key) throws -> Int {
        if let value = try? decode(Int.self, forKey: key) {
            return value
        }
        if let value = try? decode(String.self, forKey: key),
           let intValue = Int(value) {
            return intValue
        }
        if let value = try? decode(Double.self, forKey: key) {
            return Int(value)
        }
        throw DecodingError.typeMismatch(
            Int.self,
            DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected Int/String-number/Double for key '\(key.stringValue)'"
            )
        )
    }

    func decodeIntFlexibleIfPresent(forKey key: Key) throws -> Int? {
        if (try? decodeNil(forKey: key)) == true {
            return nil
        }
        return try? decodeIntFlexible(forKey: key)
    }
}
