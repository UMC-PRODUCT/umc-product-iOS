//
//  MemberRepository.swift
//  AppProduct
//
//  Created by euijjang97 on 2/24/26.
//

import Foundation
import Moya

/// 운영진 멤버 관리 Repository 실제 구현체
final class MemberRepository: MemberRepositoryProtocol, @unchecked Sendable {

    // MARK: - Property

    private let adapter: MoyaNetworkAdapter
    private let decoder: JSONDecoder
    private let studyRepository: StudyRepositoryProtocol
    private let fallbackRepository: MemberRepositoryProtocol

    // MARK: - Init

    init(
        adapter: MoyaNetworkAdapter,
        decoder: JSONDecoder = JSONDecoder(),
        studyRepository: StudyRepositoryProtocol,
        fallbackRepository: MemberRepositoryProtocol = MockMemberRepository()
    ) {
        self.adapter = adapter
        self.decoder = decoder
        self.studyRepository = studyRepository
        self.fallbackRepository = fallbackRepository
    }

    // MARK: - Function

    func fetchMembers() async throws -> [MemberManagementItem] {
        do {
            let groups = try await fetchMemberBaseStudyGroups()
            let descriptors = buildMemberDescriptors(from: groups)
            guard !descriptors.isEmpty else {
                return []
            }

            let profileByMemberID = await fetchMemberProfiles(
                memberIDs: descriptors.map(\.memberId)
            )

            let preferredGisuID = resolvedGisuID
            let members = descriptors.map { descriptor in
                let profile = profileByMemberID[descriptor.memberId]
                let record = profile.flatMap {
                    resolveRecord(
                        from: $0,
                        memberId: descriptor.memberId,
                        preferredGisuId: preferredGisuID
                    )
                }
                let outPoints = record?.resolvedPoints.filter {
                    $0.pointType.uppercased() == ChallengerPointType.out.rawValue
                } ?? []

                return MemberManagementItem(
                    memberID: descriptor.memberId,
                    challengerID: resolvedChallengerID(
                        descriptor: descriptor,
                        record: record
                    ),
                    profile: profile?.profileImageLink ?? descriptor.profileImageURL,
                    name: profile?.name.nonEmpty ?? descriptor.name,
                    nickname: profile?.nickname.nonEmpty ?? descriptor.name,
                    generation: generationText(from: record),
                    school: profile?.schoolName.nonEmpty ?? descriptor.schoolName,
                    position: descriptor.position,
                    part: descriptor.part,
                    penalty: outPoints.reduce(0) { $0 + abs($1.point) },
                    badge: false,
                    managementTeam: resolvedManagementTeam(
                        profile: profile,
                        record: record
                    ),
                    attendanceRecords: [],
                    penaltyHistory: makePenaltyHistories(from: outPoints)
                )
            }

            return members.sorted { lhs, rhs in
                if lhs.part.sortOrder == rhs.part.sortOrder {
                    return lhs.name < rhs.name
                }
                return lhs.part.sortOrder < rhs.part.sortOrder
            }
        } catch {
            return try await fallbackRepository.fetchMembers()
        }
    }

    func grantOutPoint(
        challengerId: Int,
        description: String
    ) async throws {
        let response = try await adapter.request(
            StudyRouter.createChallengerPoint(
                challengerId: challengerId,
                body: ChallengerPointCreateRequestDTO(
                    pointType: .out,
                    description: description
                )
            )
        )

        if response.data.isEmpty {
            return
        }

        let apiResponse = try decoder.decode(
            APIResponse<EmptyResult>.self,
            from: response.data
        )
        try apiResponse.validateSuccess()
    }

    func deleteOutPoint(
        challengerPointId: Int
    ) async throws {
        let response = try await adapter.request(
            StudyRouter.deleteChallengerPoint(
                challengerPointId: challengerPointId
            )
        )

        if response.data.isEmpty {
            return
        }

        let apiResponse = try decoder.decode(
            APIResponse<EmptyResult>.self,
            from: response.data
        )
        try apiResponse.validateSuccess()
    }

    func fetchAttendanceRecords(
        challengerId: Int
    ) async throws -> [MemberAttendanceRecord] {
        let response = try await adapter.request(
            AttendanceRouter.getChallengerHistory(
                challengerId: challengerId
            )
        )

        let apiResponse = try decoder.decode(
            APIResponse<[AttendanceHistoryItemDTO]>.self,
            from: response.data
        )
        let historyItems = try apiResponse.unwrap().map { $0.toDomain() }

        return historyItems.map { item in
            MemberAttendanceRecord(
                sessionTitle: item.scheduleName,
                week: 0,
                status: item.status
            )
        }
    }
}

// MARK: - Private Helper

private extension MemberRepository {
    struct GroupMemberDescriptor: Hashable {
        let memberId: Int
        let challengerId: Int?
        let name: String
        let profileImageURL: String?
        let schoolName: String
        let part: UMCPartType
        let position: String
    }

    func fetchMemberBaseStudyGroups() async throws -> [StudyGroupInfo] {
        if let allGroups = try await fetchAllStudyGroupDetails(),
           !allGroups.isEmpty {
            return allGroups
        }
        return try await studyRepository.fetchStudyGroupDetails()
    }

    func fetchAllStudyGroupDetails() async throws -> [StudyGroupInfo]? {
        guard let groupItems = try? await fetchStudyGroupNames(),
              !groupItems.isEmpty else {
            return nil
        }

        var result: [StudyGroupInfo] = []
        for groupItem in groupItems where groupItem.groupId > 0 {
            guard let detailDTO = try await fetchStudyGroupDetailDTO(
                groupId: groupItem.groupId
            ) else { continue }
            result.append(
                detailDTO.toDomain(defaultGroupName: groupItem.name)
            )
        }

        return result
    }

    func fetchStudyGroupNames() async throws -> [StudyGroupNameItemDTO]? {
        let response = try await adapter.request(
            StudyRouter.getStudyGroupNames
        )

        if let apiResponse = try? decoder.decode(
            APIResponse<StudyGroupNamesDTO>.self,
            from: response.data
        ),
           let wrapped = try? apiResponse.unwrap() {
            return wrapped.studyGroups
        }

        if let plain = try? decoder.decode(
            StudyGroupNamesDTO.self,
            from: response.data
        ) {
            return plain.studyGroups
        }

        return nil
    }

    func fetchStudyGroupDetailDTO(
        groupId: Int
    ) async throws -> StudyGroupDetailDTO? {
        let response = try await adapter.request(
            StudyRouter.getStudyGroupDetail(groupId: groupId)
        )

        if let apiResponse = try? decoder.decode(
            APIResponse<StudyGroupDetailDTO>.self,
            from: response.data
        ),
           let wrapped = try? apiResponse.unwrap() {
            return wrapped
        }

        if let plain = try? decoder.decode(
            StudyGroupDetailDTO.self,
            from: response.data
        ) {
            return plain
        }

        return nil
    }

    var resolvedGisuID: Int? {
        let gisuId = UserDefaults.standard.integer(forKey: AppStorageKey.gisuId)
        return gisuId > 0 ? gisuId : nil
    }

    func buildMemberDescriptors(
        from groups: [StudyGroupInfo]
    ) -> [GroupMemberDescriptor] {
        var descriptorByMemberId: [Int: GroupMemberDescriptor] = [:]

        groups.forEach { group in
            let school = group.leader.university
            let leaderMemberId = group.leader.memberID
                ?? Int(group.leader.serverID)
                ?? 0
            if leaderMemberId > 0 {
                descriptorByMemberId[leaderMemberId] = GroupMemberDescriptor(
                    memberId: leaderMemberId,
                    challengerId: group.leader.challengerID,
                    name: group.leader.name,
                    profileImageURL: group.leader.profileImageURL,
                    schoolName: school,
                    part: group.part,
                    position: "Leader"
                )
            }

            group.members.forEach { member in
                let memberId = member.memberID
                    ?? Int(member.serverID)
                    ?? 0
                guard memberId > 0 else { return }
                if descriptorByMemberId[memberId] == nil {
                    descriptorByMemberId[memberId] = GroupMemberDescriptor(
                        memberId: memberId,
                        challengerId: member.challengerID,
                        name: member.name,
                        profileImageURL: member.profileImageURL,
                        schoolName: member.university,
                        part: group.part,
                        position: "Member"
                    )
                }
            }
        }

        return descriptorByMemberId.values.sorted { $0.memberId < $1.memberId }
    }

    func fetchMemberProfiles(
        memberIDs: [Int]
    ) async -> [Int: MemberManagementProfileDTO] {
        var result: [Int: MemberManagementProfileDTO] = [:]

        await withTaskGroup(of: (Int, MemberManagementProfileDTO?).self) { group in
            for memberID in Set(memberIDs) where memberID > 0 {
                group.addTask { [weak self] in
                    guard let self else { return (memberID, nil) }
                    let profile = try? await self.fetchMemberProfile(memberId: memberID)
                    return (memberID, profile)
                }
            }

            for await (memberID, profile) in group {
                guard let profile else { continue }
                result[memberID] = profile
            }
        }

        return result
    }

    func fetchMemberProfile(
        memberId: Int
    ) async throws -> MemberManagementProfileDTO {
        let response = try await adapter.request(
            StudyRouter.getMemberProfile(memberId: memberId)
        )

        if let apiResponse = try? decoder.decode(
            APIResponse<MemberManagementProfileDTO>.self,
            from: response.data
        ),
           let wrapped = try? apiResponse.unwrap() {
            return wrapped
        }

        return try decoder.decode(
            MemberManagementProfileDTO.self,
            from: response.data
        )
    }

    func resolveRecord(
        from profile: MemberManagementProfileDTO,
        memberId: Int,
        preferredGisuId: Int?
    ) -> MemberManagementChallengerRecordDTO? {
        let matchedMemberRecords = profile.challengerRecords.filter {
            $0.memberId == memberId
        }

        if let preferredGisuId {
            if let matched = matchedMemberRecords.first(where: {
                $0.gisuId == preferredGisuId
            }) {
                return matched
            }

            if let matched = profile.challengerRecords.first(where: {
                $0.gisuId == preferredGisuId
            }) {
                return matched
            }
        }

        return matchedMemberRecords.first ?? profile.challengerRecords.first
    }

    func generationText(
        from record: MemberManagementChallengerRecordDTO?
    ) -> String {
        guard let gisu = record?.gisu, gisu > 0 else {
            return "-"
        }
        return "\(gisu)기"
    }

    func resolvedChallengerID(
        descriptor: GroupMemberDescriptor,
        record: MemberManagementChallengerRecordDTO?
    ) -> Int? {
        if let challengerId = record?.challengerId, challengerId > 0 {
            return challengerId
        }
        return descriptor.challengerId
    }

    func resolvedManagementTeam(
        profile: MemberManagementProfileDTO?,
        record: MemberManagementChallengerRecordDTO?
    ) -> ManagementTeam {
        guard let profile else { return .challenger }

        if let challengerId = record?.challengerId, challengerId > 0 {
            let matchedRoles = profile.roles
                .filter { $0.challengerId == nil || $0.challengerId == challengerId }
                .map(\.roleType)

            if let highestMatchedRole = matchedRoles.max() {
                return highestMatchedRole
            }
        }

        return profile.roles.map(\.roleType).max() ?? .challenger
    }

    func makePenaltyHistories(
        from outPoints: [MemberManagementPointDTO]
    ) -> [OperatorMemberPenaltyHistory] {
        outPoints.map { point in
            OperatorMemberPenaltyHistory(
                challengerPointId: point.id > 0 ? point.id : nil,
                date: ServerDateTimeConverter.parseUTCDateTimeOrTime(point.createdAt)
                    ?? Date(),
                reason: point.description.nonEmpty ?? "아웃",
                penaltyScore: abs(point.point)
            )
        }
        .sorted { $0.date > $1.date }
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
