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
