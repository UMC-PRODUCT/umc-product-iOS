//
//  MyPageProfileDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

/// 마이페이지 내 프로필 조회/수정 응답 DTO
struct MyPageProfileResponseDTO: Codable {
    let id: String
    let name: String
    let nickname: String
    let email: String
    let schoolId: String
    let schoolName: String
    let profileImageLink: String?
    let status: MemberStatus
    let roles: [MyPageRoleDTO]
    let challengerRecords: [MyPageChallengerRecordDTO]?

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
        id = try container.decodeMyPageFlexibleString(forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        nickname = try container.decode(String.self, forKey: .nickname)
        email = try container.decodeMyPageFlexibleString(forKey: .email)
        schoolId = try container.decodeMyPageFlexibleString(forKey: .schoolId)
        schoolName = try container.decode(String.self, forKey: .schoolName)
        profileImageLink = try container.decodeIfPresent(String.self, forKey: .profileImageLink)
        status = try container.decode(MemberStatus.self, forKey: .status)
        roles = try container.decodeIfPresent([MyPageRoleDTO].self, forKey: .roles) ?? []
        challengerRecords = try container.decodeIfPresent(
            [MyPageChallengerRecordDTO].self,
            forKey: .challengerRecords
        )
    }
}

struct MyPageRoleDTO: Codable {
    let id: String
    let challengerId: String
    let roleType: ManagementTeam
    let organizationType: OrganizationType
    let organizationId: String
    let responsiblePart: String?
    let gisu: String?
    let gisuId: String

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
        id = try container.decodeMyPageFlexibleString(forKey: .id)
        challengerId = try container.decodeMyPageFlexibleString(forKey: .challengerId)
        roleType = try container.decode(ManagementTeam.self, forKey: .roleType)
        organizationType = try container.decode(OrganizationType.self, forKey: .organizationType)
        organizationId = try container.decodeMyPageFlexibleString(forKey: .organizationId)
        responsiblePart = try container.decodeIfPresent(String.self, forKey: .responsiblePart)
        gisu = try container.decodeMyPageFlexibleStringIfPresent(forKey: .gisu)
        gisuId = try container.decodeMyPageFlexibleString(forKey: .gisuId)
    }
}

struct MyPageChallengerRecordDTO: Codable {
    let challengerId: String
    let memberId: String
    let gisu: String
    let part: String
    let challengerPoints: [MyPageChallengerPointDTO]
    let name: String
    let nickname: String
    let email: String?
    let schoolId: String
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
        challengerId = try container.decodeMyPageFlexibleString(forKey: .challengerId)
        memberId = try container.decodeMyPageFlexibleString(forKey: .memberId)
        gisu = try container.decodeMyPageFlexibleString(forKey: .gisu)
        part = try container.decode(String.self, forKey: .part)
        challengerPoints = try container.decodeIfPresent([MyPageChallengerPointDTO].self, forKey: .challengerPoints)
            ?? decoder.decodeMyPagePointsArrayFallback()
            ?? []
        name = try container.decode(String.self, forKey: .name)
        nickname = try container.decode(String.self, forKey: .nickname)
        email = try container.decodeMyPageFlexibleStringIfPresent(forKey: .email)
        schoolId = try container.decodeMyPageFlexibleString(forKey: .schoolId)
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
    let id: String
    let pointType: String
    let point: Double
    let description: String
    let createdAt: String

    private enum CodingKeys: String, CodingKey {
        case id
        case pointType
        case point
        case description
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeMyPageFlexibleString(forKey: .id)
        pointType = try container.decode(String.self, forKey: .pointType)
        point = try container.decodeFlexibleDouble(forKey: .point)
        description = try container.decode(String.self, forKey: .description)
        createdAt = try container.decode(String.self, forKey: .createdAt)
    }
}

extension MyPageProfileResponseDTO {
    func toProfileData() -> ProfileData {
        let records = challengerRecords ?? []
        let latestRecord = records.max { $0.gisu.intValue < $1.gisu.intValue }
        let latestRole = roles.max { ($0.gisu?.intValue ?? 0) < ($1.gisu?.intValue ?? 0) }

        let fallbackPart = latestRole?.responsiblePart
            .flatMap { UMCPartType(apiValue: $0) } ?? .pm

        let challengerInfo = ChallengerInfo(
            memberId: id.intValue,
            gen: latestRecord?.gisu.intValue ?? latestRole?.gisu?.intValue ?? 0,
            name: latestRecord?.name ?? name,
            nickname: latestRecord?.nickname ?? nickname,
            schoolName: latestRecord?.schoolName ?? schoolName,
            profileImage: latestRecord?.profileImageLink?.nonEmpty ?? profileImageLink?.nonEmpty,
            part: UMCPartType(apiValue: latestRecord?.part ?? "") ?? fallbackPart
        )

        let logs = records.map { record in
            ActivityLog(
                part: UMCPartType(apiValue: record.part) ?? .pm,
                generation: record.gisu.intValue,
                role: .challenger
            )
        }

        return ProfileData(
            challengeId: latestRecord?.challengerId.intValue ?? latestRole?.challengerId.intValue ?? 0,
            challangerInfo: challengerInfo,
            socialConnected: [],
            activityLogs: logs,
            profileLink: []
        )
    }
}

private extension String {
    var intValue: Int { Int(self) ?? 0 }

    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
