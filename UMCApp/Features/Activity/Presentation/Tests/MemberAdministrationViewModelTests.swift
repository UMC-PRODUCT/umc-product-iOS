// Created by euijjang97 on 11/1/26.
import Foundation
import Testing
import ActivityDomain
import CoreDomain
import UMCFoundation
@testable import ActivityPresentation

private func adminMember(_ id: String) -> AdminMember {
    AdminMember(id: id, member: .init(memberID: "member-\(id)", challengerID: id,
        profile: nil, name: id, nickname: id, generation: "10기", school: "학교",
        position: "", part: .front(type: .ios), penalty: 0, badge: false,
        managementTeam: .challenger, attendanceRecords: [], penaltyHistory: []),
        gisuId: "10", schoolId: "20", generation: "10")
}

private actor SearchGate {
    var started = false
    var releaseContinuation: CheckedContinuation<Void, Never>?
    var startContinuation: CheckedContinuation<Void, Never>?
    func pause() async {
        started = true
        startContinuation?.resume()
        startContinuation = nil
        await withCheckedContinuation { releaseContinuation = $0 }
    }
    func waitForStart() async {
        if started { return }
        await withCheckedContinuation { startContinuation = $0 }
    }
    func release() { releaseContinuation?.resume(); releaseContinuation = nil }
}

private final class AdministrationFake: MemberAdministrationUseCaseProtocol {
    var authority = MemberAdministrationAuthority(roles: [], isSuperAdmin: true)
    var gate: SearchGate?
    var organizationGate: SearchGate?
    var organizationFails = false
    var generationsFail = false
    var nextPageFails = false
    var lastPage: Int?
    var generationOptions = [MemberFilterOption(id: "10", name: "10기", isActive: true)]
    var lastFilter: MemberSearchFilter?
    func search(filter: MemberSearchFilter, page: Int) async throws -> AdminMemberPage {
        lastFilter = filter
        lastPage = page
        if page > 0 && nextPageFails { throw URLError(.badServerResponse) }
        if filter.keyword == "old", let gate { await gate.pause() }
        return .init(members: [adminMember(filter.keyword.isEmpty ? "initial" : filter.keyword)], hasNext: true)
    }
    func fetchGenerations() async throws -> [MemberFilterOption] {
        if generationsFail { throw URLError(.badServerResponse) }
        return generationOptions
    }
    func fetchOrganizations(gisuId: String) async throws -> MemberOrganizationOptions {
        if organizationFails { throw DomainError.custom(message: "조직 조회 실패") }
        if let organizationGate { await organizationGate.pause() }
        return .init(chapters: [.init(id: "30", name: "지부")],
              schools: [.init(id: "20", name: "학교", parentId: "30")])
    }
    func fetchAuthority() async throws -> MemberAdministrationAuthority { authority }
    func updatePointDescription(pointId: String, description: String) async throws {}
}

private final class MemberActionsFake: FetchMembersUseCaseProtocol {
    var history: [OperatorMemberPenaltyHistory] = []
    var historyFails = false
    var grantCount = 0
    var deletedId: String?
    func execute(mode: ActivityMode) async throws -> [MemberManagementItem] { [] }
    func executePage(page: Int, mode: ActivityMode) async throws -> MemberPage {
        .init(members: [], hasNext: false, currentPage: page)
    }
    func grantPoint(challengerId: String, pointType: ChallengerPointType,
                    pointValue: Int, description: String) async throws {
        grantCount += 1
        history = [.init(challengerPointId: "saved-point", date: .now, reason: description,
                         penaltyScore: 3, pointType: pointType, signedPoint: Double(pointValue))]
    }
    func deletePoint(challengerPointId: String) async throws { deletedId = challengerPointId; history = [] }
    func fetchPointHistory(challengerId: String) async throws -> [OperatorMemberPenaltyHistory] {
        if historyFails { throw DomainError.custom(message: "조회 거부") }
        return history
    }
    func fetchAllGenerations(memberId: String) async throws -> String { "10기" }
    func fetchGenerationPointSummaries(memberId: String) async throws -> [GenerationPointSummary] { [] }
    func fetchAttendanceRecords(memberId: String) async throws -> [MemberAttendanceRecord] { [] }
}

@MainActor
struct MemberAdministrationViewModelTests {
    @Test func cancelledSearchClearsItsLoadingState() async {
        let api = AdministrationFake()
        let gate = SearchGate()
        api.gate = gate
        let vm = MemberAdministrationViewModel(useCase: api, membersUseCase: MemberActionsFake(),
                                               session: UserSessionManager())
        await vm.load()
        vm.filter.keyword = "old"
        let pending = Task { await vm.search() }
        await gate.waitForStart()
        pending.cancel()
        await gate.release()
        await pending.value
        #expect(!vm.isLoading)
    }
    @Test func searchDuringOrganizationLoadDoesNotDiscardOptions() async {
        let api = AdministrationFake()
        let vm = MemberAdministrationViewModel(useCase: api, membersUseCase: MemberActionsFake(),
                                               session: UserSessionManager())
        await vm.load()
        let gate = SearchGate()
        api.organizationGate = gate
        let changing = Task { await vm.changeGeneration() }
        await gate.waitForStart()
        #expect(vm.filterOptionsState == .loading)
        api.lastFilter = nil
        vm.filter.keyword = "new"
        await vm.search()
        #expect(api.lastFilter == nil)
        await gate.release()
        await changing.value
        #expect(vm.filterOptionsState == .ready)
        #expect(vm.organizations.schools.map(\.id) == ["20"])
        #expect(vm.members.map(\.id) == ["new"])
    }

    @Test func paginationUsesTheFilterThatProducedDisplayedMembers() async {
        let api = AdministrationFake()
        let vm = MemberAdministrationViewModel(useCase: api, membersUseCase: MemberActionsFake(),
                                               session: UserSessionManager())
        await vm.load()
        vm.filter.keyword = "not-applied"
        await vm.loadMore()
        #expect(api.lastFilter?.keyword == "")
        #expect(vm.members.map(\.id) == ["initial"])
    }

    @Test("중앙 교육국은 기수 조회 실패 후 재시도하면 필터와 멤버 목록을 복구한다")
    func retryRecoversGenerationFailureForCentralEducation() async {
        let api = AdministrationFake()
        api.authority = .init(roles: [.init(
            gisu: "10", gisuId: "10", roleType: .centralEducationTeamMember,
            organizationType: .central, organizationId: nil
        )])
        api.generationsFail = true
        let vm = MemberAdministrationViewModel(
            useCase: api, membersUseCase: MemberActionsFake(), session: UserSessionManager()
        )

        await vm.load()

        #expect(vm.errorMessage != nil)
        #expect(!vm.isLoading)
        #expect(vm.generations.isEmpty)
        #expect(vm.organizations.schools.isEmpty)
        #expect(vm.members.isEmpty)
        #expect(api.lastFilter == nil)

        api.generationsFail = false
        await vm.retry()

        #expect(vm.errorMessage == nil)
        #expect(!vm.isLoading)
        #expect(vm.generations.map(\.id) == ["10"])
        #expect(vm.filter.gisuId == "10")
        #expect(vm.availableSchools.map(\.id) == ["20"])
        #expect(vm.canSelectAllSchools)
        #expect(vm.members.map(\.id) == ["initial"])
        #expect(api.lastFilter?.gisuId == "10")
        #expect(api.lastFilter?.schoolId == nil)
    }

    @Test func resetRestoresAuthorizedDefaultScopeAndKeepsKeyword() async {
        let api = AdministrationFake()
        api.generationOptions.append(.init(id: "9", name: "9기"))
        api.authority = .init(roles: ["10", "9"].map { gisu in
            .init(gisu: gisu, gisuId: gisu, roleType: .schoolPresident,
                  organizationType: .school, organizationId: "20")
        })
        let vm = MemberAdministrationViewModel(useCase: api, membersUseCase: MemberActionsFake(),
                                               session: UserSessionManager())
        await vm.load()
        #expect(!vm.canResetFilters)
        vm.filter.gisuId = "9"
        vm.filter.keyword = "검색"
        vm.filter.part = "IOS"
        await vm.changeGeneration()
        #expect(vm.canResetFilters)
        #expect(vm.filterSummary.contains("9기"))
        #expect(vm.filterSummary.contains("학교"))
        await vm.resetFilters()
        #expect(!vm.canResetFilters)
        #expect(api.lastFilter == .init(keyword: "검색", gisuId: "10", schoolId: "20"))
    }

    @Test func paginationFailureKeepsResultsAndRetriesSamePage() async {
        let api = AdministrationFake()
        let vm = MemberAdministrationViewModel(useCase: api, membersUseCase: MemberActionsFake(),
                                               session: UserSessionManager())
        await vm.load()
        api.nextPageFails = true
        await vm.loadMore()
        #expect(vm.nextPageError != nil)
        #expect(vm.errorMessage == nil)
        #expect(vm.members.map(\.id) == ["initial"])
        #expect(api.lastPage == 1)
        api.nextPageFails = false
        await vm.loadMore()
        #expect(vm.nextPageError == nil)
        #expect(api.lastPage == 1)
    }

    @Test func retryRecoversOrganizationFailure() async {
        let api = AdministrationFake()
        api.organizationFails = true
        let vm = MemberAdministrationViewModel(useCase: api, membersUseCase: MemberActionsFake(),
                                               session: UserSessionManager())
        await vm.load()
        #expect(vm.errorMessage != nil)
        #expect(vm.filterOptionsState == .failed("조직 조회 실패"))
        await vm.search()
        #expect(api.lastFilter == nil)
        #expect(vm.errorMessage != nil)
        api.organizationFails = false
        await vm.retry()
        #expect(vm.organizations.schools.map(\.id) == ["20"])
        #expect(vm.errorMessage == nil)
    }

    @Test func staleSearchCannotReplaceNewResults() async {
        let api = AdministrationFake()
        let gate = SearchGate()
        api.gate = gate
        let vm = MemberAdministrationViewModel(useCase: api, membersUseCase: MemberActionsFake(),
                                               session: UserSessionManager())
        await vm.load()
        vm.filter.keyword = "old"
        let old = Task { await vm.search() }
        await gate.waitForStart()
        vm.filter.keyword = "new"
        await vm.search()
        await gate.release()
        await old.value
        #expect(vm.members.map(\.id) == ["new"])
        #expect(!vm.isLoading)
    }

    @Test func schoolStaffSearchIsScopedAndMutationIsDenied() async {
        let api = AdministrationFake()
        api.authority = .init(roles: [.init(gisu: "10", gisuId: "10",
            roleType: .schoolPartLeader, organizationType: .school, organizationId: "20")])
        let actions = MemberActionsFake()
        let vm = MemberAdministrationViewModel(useCase: api, membersUseCase: actions,
                                               session: UserSessionManager())
        await vm.load()
        #expect(api.lastFilter?.schoolId == "20")
        await vm.select(adminMember("target"))
        #expect(!vm.canManageSelected)
        let success = await vm.grant(type: .custom, value: 3, reason: "사유")
        #expect(!success)
        #expect(actions.grantCount == 0)
    }

    @Test func newlyGrantedHistoryHasServerIdAndCanImmediatelyBeDeleted() async throws {
        let actions = MemberActionsFake()
        let vm = MemberAdministrationViewModel(useCase: AdministrationFake(), membersUseCase: actions,
                                               session: UserSessionManager())
        await vm.load()
        await vm.select(adminMember("target"))
        #expect(await vm.grant(type: .custom, value: 3, reason: "사유"))
        let saved = try #require(vm.history.first)
        #expect(saved.challengerPointId == "saved-point")
        #expect(vm.history.count == 1)
        await vm.delete(saved)
        #expect(actions.deletedId == "saved-point")
        #expect(vm.history.isEmpty)
    }

    @Test func historyFailureIsNotDisplayedAsEmptySuccess() async {
        let actions = MemberActionsFake()
        actions.historyFails = true
        let vm = MemberAdministrationViewModel(useCase: AdministrationFake(), membersUseCase: actions,
                                               session: UserSessionManager())
        await vm.load()
        await vm.select(adminMember("target"))
        #expect(vm.detailError != nil)
        #expect(!vm.isLoadingDetail)
        actions.historyFails = false
        await vm.reloadHistory()
        #expect(vm.detailError == nil)
    }

    @Test func invalidOrLegacyGrantNeverReachesServer() async {
        let actions = MemberActionsFake()
        let vm = MemberAdministrationViewModel(useCase: AdministrationFake(), membersUseCase: actions,
                                               session: UserSessionManager())
        await vm.load()
        await vm.select(adminMember("target"))
        #expect(!(await vm.grant(type: .bestWorkbook, value: 2, reason: "사유")))
        #expect(!(await vm.grant(type: .custom, value: 0, reason: "사유")))
        #expect(!(await vm.grant(type: .studyLate, value: -3, reason: "사유")))
        #expect(!(await vm.grant(type: .custom, value: 3, reason: String(repeating: "가", count: 201))))
        #expect(actions.grantCount == 0)
    }
}
