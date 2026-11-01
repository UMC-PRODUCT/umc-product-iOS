// Created by euijjang97 on 11/1/26.
import Foundation
import ActivityDomain
import CoreDomain
import CoreNetwork
import UMCFoundation
import Moya

/// 운영진의 기수·조직 검색과 사유 정정을 처리합니다.
public final class MemberAdministrationRepository:
    MemberAdministrationRepositoryProtocol, @unchecked Sendable {
    private let networkRequesting: any NetworkRequesting

    public convenience init(adapter: MoyaNetworkAdapter) {
        self.init(networkRequesting: adapter)
    }

    init(networkRequesting: any NetworkRequesting) {
        self.networkRequesting = networkRequesting
    }

    public func search(filter: MemberSearchFilter, page: Int) async throws -> AdminMemberPage {
        let result: AdminSearchResultDTO = try await fetch(
            .search(MemberAdministrationQuery(filter: filter, page: page))
        )
        let members = result.page.content.compactMap { item -> AdminMember? in
            guard !item.challengerId.isEmpty, !item.memberId.isEmpty else { return nil }
            let team = ManagementTeam.highestPriority(
                in: item.roleTypes.compactMap(ManagementTeam.init(rawValue:))
            ) ?? .challenger
            let member = MemberManagementItem(
                memberID: item.memberId, challengerID: item.challengerId,
                profile: item.profileImageLink, name: item.name, nickname: item.nickname,
                generation: item.generation.isEmpty ? "" : "\(item.generation)기",
                school: item.schoolName, position: team.korean,
                part: item.part.isEmpty ? .admin : UMCPartType(apiValue: item.part) ?? .admin,
                penalty: 0, rewardPoints: 0, badge: false, managementTeam: team,
                attendanceRecords: [], penaltyHistory: []
            )
            return AdminMember(
                id: item.challengerId, member: member, gisuId: item.gisuId,
                schoolId: item.schoolId, generation: item.generation
            )
        }
        return AdminMemberPage(members: members, hasNext: result.page.hasNext)
    }

    public func fetchGenerations() async throws -> [MemberFilterOption] {
        let result: AdminGenerationListDTO = try await fetch(.generations)
        return result.gisuList.sorted {
            (Int($0.generation) ?? 0) > (Int($1.generation) ?? 0)
        }.map {
            MemberFilterOption(id: $0.gisuId, name: "\($0.generation)기", isActive: $0.isActive)
        }
    }

    public func fetchOrganizations(gisuId: String) async throws -> MemberOrganizationOptions {
        let result: AdminOrganizationListDTO = try await fetch(
            .organizations(MemberOrganizationQuery(gisuId: gisuId))
        )
        guard let organization = result.gisus.first(where: { $0.gisuId == gisuId }) else {
            throw DomainError.custom(message: "선택한 기수의 조직 정보를 찾을 수 없습니다.")
        }
        let chapters = organization.chapters.map {
            MemberFilterOption(id: $0.chapterId, name: $0.chapterName)
        }
        var schools = organization.schools.map {
            MemberFilterOption(
                id: $0.schoolId, name: $0.schoolName,
                parentId: $0.chapterId.isEmpty ? nil : $0.chapterId
            )
        }
        // 서버가 학교 상세 목록을 생략한 경우에도 지부 안의 학교는 선택할 수 있습니다.
        if schools.isEmpty {
            schools = organization.chapters.flatMap { chapter in
                chapter.schools.map {
                    MemberFilterOption(
                        id: $0.schoolId, name: $0.schoolName, parentId: chapter.chapterId
                    )
                }
            }
        }
        return MemberOrganizationOptions(chapters: chapters, schools: schools)
    }

    public func fetchAuthority() async throws -> MemberAdministrationAuthority {
        let response = try await networkRequesting.request(MemberProfileRouter.getMyProfile)
        let profile = try JSONDecoder().decode(
            APIResponse<MemberProfileResponseDTO>.self, from: response.data
        ).unwrap().toDomain()
        let authority: AdminSystemAuthorityDTO = try await fetch(.authority)
        return MemberAdministrationAuthority(
            roles: profile.roles, isSuperAdmin: authority.isSuperAdmin
        )
    }

    public func updatePointDescription(pointId: String, description: String) async throws {
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              description.utf16.count <= 200 else {
            throw DomainError.custom(message: "사유를 1~200자로 입력해주세요.")
        }
        let response = try await networkRequesting.request(
            MemberAdministrationRouter.updateDescription(
                pointId, UpdatePointDescriptionRequestDTO(newDescription: description)
            )
        )
        guard !response.data.isEmpty else { return }
        try JSONDecoder().decode(
            APIResponse<EmptyResult>.self, from: response.data
        ).validateSuccess()
    }

    private func fetch<Result: Codable>(
        _ target: MemberAdministrationRouter
    ) async throws -> Result {
        let response = try await networkRequesting.request(target)
        return try JSONDecoder().decode(APIResponse<Result>.self, from: response.data).unwrap()
    }
}
