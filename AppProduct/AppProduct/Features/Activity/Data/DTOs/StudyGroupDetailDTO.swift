//
//  StudyGroupDetailDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/18/26.
//

import Foundation

/// 스터디 그룹 상세 응답 DTO
///
/// `GET /api/v1/study-groups/{groupId}`
struct StudyGroupDetailDTO: Codable, Sendable, Equatable {
    let groupId: Int
    let name: String
    let part: String
    let partDisplayName: String?
    let schools: [StudyGroupSchoolDTO]
    let createdAt: String
    let memberCount: Int
    let leader: StudyGroupChallengerDTO
    let members: [StudyGroupChallengerDTO]
}

struct StudyGroupSchoolDTO: Codable, Sendable, Equatable {
    let schoolId: Int
    let schoolName: String
    let logoImageId: String?
    let totalStudyGroupCount: Int
    let totalMemberCount: Int
}

struct StudyGroupChallengerDTO: Codable, Sendable, Equatable {
    let challengerId: Int
    let memberId: Int
    let name: String
    let profileImageUrl: String?
    let bestWorkbookPoint: Int?
}

extension StudyGroupDetailDTO {
    func toDomain(defaultGroupName: String? = nil) -> StudyGroupInfo {
        let partType = UMCPartType(apiValue: part) ?? .front(type: .ios)
        let university = schools.first?.schoolName ?? ""
        let parsedDate = Self.parseISO8601Date(createdAt) ?? Date()

        let leaderMember = StudyGroupMember(
            serverID: String(leader.memberId),
            name: leader.name,
            university: university,
            profileImageURL: normalizedURL(leader.profileImageUrl),
            role: .leader,
            bestWorkbookPoint: leader.bestWorkbookPoint ?? 0
        )

        let memberItems = members.map { member in
            StudyGroupMember(
                serverID: String(member.memberId),
                name: member.name,
                university: university,
                profileImageURL: normalizedURL(member.profileImageUrl),
                role: .member,
                bestWorkbookPoint: member.bestWorkbookPoint ?? 0
            )
        }

        return StudyGroupInfo(
            serverID: String(groupId),
            name: name.isEmpty ? (defaultGroupName ?? "") : name,
            part: partType,
            createdDate: parsedDate,
            leader: leaderMember,
            members: memberItems
        )
    }

    private func normalizedURL(_ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        return value
    }

    private static func parseISO8601Date(_ value: String) -> Date? {
        let formatterWithFraction = ISO8601DateFormatter()
        formatterWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatterWithFraction.date(from: value) {
            return date
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}
