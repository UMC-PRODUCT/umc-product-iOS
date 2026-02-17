//
//  MyPageProfileDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

/// 마이페이지 내 프로필 조회/수정 응답 DTO
struct MyPageProfileResponseDTO: Codable {
    let id: Int
    let name: String
    let nickname: String
    let email: String
    let schoolId: Int
    let schoolName: String
    let profileImageLink: String?
    let status: MemberStatus
    let roles: [MyPageRoleDTO]
    let challengerRecords: [MyPageChallengerRecordDTO]?
}

struct MyPageRoleDTO: Codable {
    let id: Int
    let challengerId: Int
    let roleType: ManagementTeam
    let organizationType: OrganizationType
    let organizationId: Int
    let responsiblePart: String?
    let gisu: Int?
    let gisuId: Int
}

struct MyPageChallengerRecordDTO: Codable {
    let challengerId: Int
    let memberId: Int
    let gisu: Int
    let part: String
    let challengerPoints: [MyPageChallengerPointDTO]
    let name: String
    let nickname: String
    let email: String
    let schoolId: Int
    let schoolName: String
    let profileImageLink: String?
    let status: MemberStatus

    private enum CodingKeys: String, CodingKey {
        case challengerId
        case memberId
        case gisu
        case part
        case challengerPoints
        case name
        case nickname
        case email
        case schoolId
        case schoolName
        case profileImageLink
        case status
    }

    private enum FallbackCodingKeys: String, CodingKey {
        case memberStatus
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        challengerId = try container.decode(Int.self, forKey: .challengerId)
        memberId = try container.decode(Int.self, forKey: .memberId)
        gisu = try container.decode(Int.self, forKey: .gisu)
        part = try container.decode(String.self, forKey: .part)
        challengerPoints = try container.decodeIfPresent([MyPageChallengerPointDTO].self, forKey: .challengerPoints)
            ?? decoder.decodeMyPagePointsArrayFallback()
            ?? []
        name = try container.decode(String.self, forKey: .name)
        nickname = try container.decode(String.self, forKey: .nickname)
        email = try container.decode(String.self, forKey: .email)
        schoolId = try container.decode(Int.self, forKey: .schoolId)
        schoolName = try container.decode(String.self, forKey: .schoolName)
        profileImageLink = try container.decodeIfPresent(String.self, forKey: .profileImageLink)
        let fallbackContainer = try decoder.container(keyedBy: FallbackCodingKeys.self)
        status = try container.decodeIfPresent(MemberStatus.self, forKey: .status)
            ?? fallbackContainer.decode(MemberStatus.self, forKey: .memberStatus)
    }
}

private struct MyPageDynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

private extension Decoder {
    func decodeMyPagePointsArrayFallback() throws -> [MyPageChallengerPointDTO]? {
        let container = try self.container(keyedBy: MyPageDynamicCodingKey.self)
        guard let key = MyPageDynamicCodingKey(stringValue: "points") else {
            return nil
        }
        return try container.decodeIfPresent([MyPageChallengerPointDTO].self, forKey: key)
    }
}

struct MyPageChallengerPointDTO: Codable {
    let id: Int
    let pointType: String
    let point: Double
    let description: String
    let createdAt: String
}

extension MyPageProfileResponseDTO {
    func toProfileData() -> ProfileData {
        let records = challengerRecords ?? []
        let latestRecord = records.max { $0.gisu < $1.gisu }
        let latestRole = roles.max { ($0.gisu ?? 0) < ($1.gisu ?? 0) }

        let fallbackPart = latestRole?.responsiblePart
            .flatMap { UMCPartType(apiValue: $0) } ?? .pm

        let challengerInfo = ChallengerInfo(
            memberId: id,
            gen: latestRecord?.gisu ?? latestRole?.gisu ?? 0,
            name: latestRecord?.name ?? name,
            nickname: latestRecord?.nickname ?? nickname,
            schoolName: latestRecord?.schoolName ?? schoolName,
            profileImage: latestRecord?.profileImageLink ?? profileImageLink,
            part: UMCPartType(apiValue: latestRecord?.part ?? "") ?? fallbackPart
        )

        let logs = records.map { record in
            ActivityLog(
                part: UMCPartType(apiValue: record.part) ?? .pm,
                generation: record.gisu,
                role: .challenger
            )
        }

        return ProfileData(
            challengeId: latestRecord?.challengerId ?? latestRole?.challengerId ?? 0,
            challangerInfo: challengerInfo,
            socialConnected: [],
            activityLogs: logs,
            profileLink: []
        )
    }
}
