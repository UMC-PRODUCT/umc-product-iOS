//
//  StubMemberRepository.swift
//  UMCApp
//
//  Created by jaewon Lee on 8/4/26.
//

#if DEBUG
import ActivityDomain
import CoreDomain
import UMCFoundation

/// stub 세션에서 멤버 관리 화면을 서버 없이 표시하는 Repository.
///
/// 목록·검색·상세 조회는 픽스처를 반환한다. 상벌점 부여/삭제는 실제 요청으로 넘어가지
/// 않도록 미지원 에러를 던진다.
struct StubMemberRepository: MemberRepositoryProtocol {

    // MARK: - 멤버 목록

    func fetchMembers(mode: ActivityMode = .challenger) async throws -> [MemberManagementItem] {
        StubSessionFixtures.members
    }

    func fetchMembersPage(page: Int, mode: ActivityMode = .challenger) async throws -> MemberPage {
        guard page == 0 else {
            return MemberPage(members: [], hasNext: false, currentPage: page)
        }
        return MemberPage(members: StubSessionFixtures.members, hasNext: false, currentPage: 0)
    }

    // MARK: - 챌린저 검색

    func searchChallengers(
        keyword: String?,
        cursor: Int?,
        size: Int
    ) async throws -> ChallengerSearchPage {
        let members = StubSessionFixtures.members.map { member in
            ChallengerInfo(
                memberId: member.memberID ?? "",
                challengerId: member.challengerID,
                gen: member.generation,
                name: member.name,
                nickname: member.nickname,
                schoolName: member.school,
                profileImage: member.profile,
                part: member.part
            )
        }
        // 서버 검색은 로그인한 본인도 돌려준다. 빼 두면 본인을 고르는 경로(#1675)를 stub
        // 세션에서 재현할 수 없다.
        let candidates = [signedInChallenger].compactMap { $0 } + members
        guard let keyword, !keyword.isEmpty else {
            return ChallengerSearchPage(challengers: candidates, hasNext: false, nextCursor: nil)
        }
        let filtered = candidates.filter {
            $0.name.localizedCaseInsensitiveContains(keyword)
                || $0.nickname.localizedCaseInsensitiveContains(keyword)
        }
        return ChallengerSearchPage(challengers: filtered, hasNext: false, nextCursor: nil)
    }

    /// 지금 신원을 검색 결과 한 줄로 바꾼다. 챌린저 기록이 없는 신원(제품팀)은 검색에 나오지 않는다.
    private var signedInChallenger: ChallengerInfo? {
        let profile = StubSessionFixtures.profile
        guard let challengerId = profile.latestChallengerId,
              let generation = profile.generations.first,
              let part = profile.responsiblePart.flatMap(UMCPartType.init(apiValue:)) else {
            return nil
        }
        return ChallengerInfo(
            memberId: profile.memberId,
            challengerId: challengerId,
            gen: generation,
            name: profile.name,
            nickname: profile.nickname,
            schoolName: profile.schoolName,
            profileImage: profile.profileImageLink,
            part: part
        )
    }

    // MARK: - 상벌점 부여 / 삭제

    func grantPoint(
        challengerId: String,
        pointType: ChallengerPointType,
        pointValue: Int,
        description: String
    ) async throws {
        throw StubSessionError.unsupported(action: "상벌점 부여")
    }

    func deletePoint(challengerPointId: String) async throws {
        throw StubSessionError.unsupported(action: "상벌점 삭제")
    }

    func fetchPointHistory(
        challengerId: String, mode: ActivityMode
    ) async throws -> [OperatorMemberPenaltyHistory] {
        member(challengerId: challengerId)?.penaltyHistory ?? []
    }

    // MARK: - 멤버 상세

    func fetchAllGenerations(memberId: String) async throws -> String {
        member(memberId: memberId)?.generation ?? "12기"
    }

    func fetchGenerationPointSummaries(
        memberId: String
    ) async throws -> [GenerationPointSummary] {
        member(memberId: memberId)?.generationPoints ?? []
    }

    func fetchAttendanceRecords(
        memberId: String
    ) async throws -> [MemberAttendanceRecord] {
        member(memberId: memberId)?.attendanceRecords ?? []
    }

    // MARK: - Private Function

    private func member(memberId: String) -> MemberManagementItem? {
        StubSessionFixtures.members.first { $0.memberID == memberId }
    }

    private func member(challengerId: String) -> MemberManagementItem? {
        StubSessionFixtures.members.first { $0.challengerID == challengerId }
    }
}
/// 새 운영 화면도 stub 세션에서는 실제 서버에 접근하지 않습니다.
struct StubMemberAdministrationRepository: MemberAdministrationRepositoryProtocol {
    func search(filter: MemberSearchFilter, page: Int) async throws -> AdminMemberPage {
        let members = StubSessionFixtures.members.filter {
            (filter.keyword.isEmpty || $0.name.localizedCaseInsensitiveContains(filter.keyword)
             || $0.nickname.localizedCaseInsensitiveContains(filter.keyword))
                && (filter.part == nil || $0.part.apiValue == filter.part)
        }.map {
            AdminMember(id: $0.challengerID ?? "", member: $0, gisuId: "10",
                        schoolId: "3", generation: "12")
        }
        return .init(members: page == 0 ? members : [], hasNext: false)
    }
    func fetchGenerations() async throws -> [MemberFilterOption] {
        [.init(id: "10", name: "12기", isActive: true)]
    }
    func fetchOrganizations(gisuId: String) async throws -> MemberOrganizationOptions {
        .init(chapters: [.init(id: "2", name: "GACI")],
              schools: [.init(id: "3", name: "한성대학교", parentId: "2")])
    }
    func fetchAuthority() async throws -> MemberAdministrationAuthority {
        .init(roles: StubSessionFixtures.profile.roles)
    }
    func updatePointDescription(pointId: String, description: String) async throws {
        throw StubSessionError.unsupported(action: "상벌점 사유 수정")
    }
}
#endif
