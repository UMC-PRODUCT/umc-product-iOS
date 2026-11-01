// Created by euijjang97 on 11/1/26.
import ActivityDomain
import CoreDomain
import SwiftUI
import UMCFoundation

/// 검색 조건별 요청 세대를 분리하고, 상세 기록은 서버 응답만 표시합니다.
@MainActor @Observable
final class MemberAdministrationViewModel {
    private let useCase: MemberAdministrationUseCaseProtocol
    private let membersUseCase: FetchMembersUseCaseProtocol
    private let session: UserSessionManager
    private(set) var authority = MemberAdministrationAuthority(roles: [])
    private(set) var generations: [MemberFilterOption] = []
    private(set) var organizations = MemberOrganizationOptions(chapters: [], schools: [])
    private(set) var members: [AdminMember] = []
    private(set) var isLoading = false
    private(set) var isLoadingNextPage = false
    private(set) var isMutating = false
    private(set) var isLoadingDetail = false
    private(set) var errorMessage: String?
    private(set) var organizationError: String?
    private(set) var detailError: String?
    private(set) var actionError: String?
    private(set) var history: [OperatorMemberPenaltyHistory] = []
    var selectedMember: AdminMember?
    var filter = MemberSearchFilter()
    private var requestVersion = 0
    private var organizationVersion = 0
    private var appliedFilter: MemberSearchFilter?
    private var detailVersion = 0
    private var page = 0
    private var hasNext = false
    private var loaded = false
    private var organizationLoadFailed = false

    var hasMore: Bool { hasNext }

    init(useCase: MemberAdministrationUseCaseProtocol, membersUseCase: FetchMembersUseCaseProtocol,
         session: UserSessionManager) {
        self.useCase = useCase
        self.membersUseCase = membersUseCase
        self.session = session
    }

    var canManageSelected: Bool {
        guard let selectedMember else { return false }
        return authority.canManagePoints(gisuId: selectedMember.gisuId,
                                         schoolId: selectedMember.schoolId)
    }
    var canDeleteSelected: Bool {
        selectedMember.map { authority.canDeletePoints(gisuId: $0.gisuId) } ?? false
    }
    var availablePointTypes: [ChallengerPointType] {
        guard canManageSelected, let selectedMember else { return [] }
        return MemberPointValidation.availableTypes(generation: selectedMember.generation)
    }
    var availableChapters: [MemberFilterOption] {
        if authority.canSearchAllSchools(gisuId: filter.gisuId) { return organizations.chapters }
        let ids = authority.roles.filter {
            $0.gisuId == filter.gisuId && $0.organizationType == .chapter
                && $0.roleType == .chapterPresident
        }.compactMap(\.organizationId)
        return organizations.chapters.filter { ids.contains($0.id) }
    }
    var availableSchools: [MemberFilterOption] {
        let schools = organizations.schools.filter {
            filter.chapterId == nil || $0.parentId == filter.chapterId
        }
        if authority.canSearchAllSchools(gisuId: filter.gisuId) || !availableChapters.isEmpty {
            return schools
        }
        let ids = authority.roles.filter {
            $0.gisuId == filter.gisuId && $0.organizationType == .school
                && $0.roleType.canAccessAdminMode
        }.compactMap(\.organizationId)
        return schools.filter { ids.contains($0.id) }
    }
    var canSelectAllSchools: Bool {
        authority.canSearchAllSchools(gisuId: filter.gisuId) || !availableChapters.isEmpty
    }
    var canSelectAllChapters: Bool { authority.canSearchAllSchools(gisuId: filter.gisuId) }

    func load() async {
        guard !loaded else { return }
        isLoading = true
        errorMessage = nil
        let sessionRevision = session.sessionRevision
        do {
            let fetchedAuthority = try await useCase.fetchAuthority()
            try Task.checkCancellation()
            guard sessionRevision == session.sessionRevision else { return }
            authority = fetchedAuthority
            session.updateSystemAdministrator(authority.isSuperAdmin, expectedRevision: sessionRevision)
            let all = try await useCase.fetchGenerations()
            generations = all.filter { option in
                authority.isSuperAdmin || authority.roles.contains {
                    $0.gisuId == option.id && $0.roleType.canAccessAdminMode
                }
            }
            guard let initial = generations.first(where: \.isActive) ?? generations.first else {
                throw DomainError.custom(message: "관리할 수 있는 기수가 없습니다.")
            }
            filter.gisuId = initial.id
            loaded = true
            await changeGeneration()
        } catch {
            errorMessage = message(error)
            isLoading = false
        }
    }

    func changeGeneration() async {
        requestVersion += 1
        organizationVersion += 1
        let version = organizationVersion
        let gisuId = filter.gisuId
        filter.chapterId = nil
        filter.schoolId = nil
        members = []
        appliedFilter = nil
        hasNext = false
        page = 0
        isLoadingNextPage = false
        organizations = .init(chapters: [], schools: [])
        isLoading = true
        errorMessage = nil
        organizationLoadFailed = false
        organizationError = nil
        do {
            let options = try await useCase.fetchOrganizations(gisuId: gisuId)
            guard version == organizationVersion, filter.gisuId == gisuId else { return }
            organizations = options
            filter = try authority.scopedFilter(filter)
            await search()
        } catch {
            guard version == organizationVersion else { return }
            organizationLoadFailed = true
            errorMessage = message(error)
            organizationError = message(error)
            isLoading = false
        }
    }

    func retry() async {
        if !loaded { await load() }
        else if organizationLoadFailed { await changeGeneration() }
        else { await search() }
    }

    func search() async {
        requestVersion += 1
        let version = requestVersion
        isLoading = true
        defer { if version == requestVersion { isLoading = false } }
        isLoadingNextPage = false
        errorMessage = nil
        members = []
        hasNext = false
        do {
            let query = try authority.scopedFilter(filter)
            filter = query
            let result = try await useCase.search(filter: query, page: 0)
            guard version == requestVersion, !Task.isCancelled else { return }
            members = result.members
            appliedFilter = query
            page = 0
            hasNext = result.hasNext
        } catch {
            guard version == requestVersion, !Task.isCancelled else { return }
            errorMessage = message(error)
        }
    }

    func loadMore() async {
        guard hasNext, !isLoading, !isLoadingNextPage, let query = appliedFilter else { return }
        let version = requestVersion
        isLoadingNextPage = true
        defer { if version == requestVersion { isLoadingNextPage = false } }
        do {
            let result = try await useCase.search(filter: query, page: page + 1)
            guard version == requestVersion, query == appliedFilter else { return }
            let existing = Set(members.map(\.id))
            members += result.members.filter { !existing.contains($0.id) }
            page += 1
            hasNext = result.hasNext
        } catch {
            guard version == requestVersion else { return }
            errorMessage = message(error)
        }
    }

    func select(_ member: AdminMember) async {
        guard !isMutating else { return }
        selectedMember = member
        history = []
        actionError = nil
        await reloadHistory()
    }

    func reloadHistory() async {
        guard let target = selectedMember else { return }
        detailVersion += 1
        let version = detailVersion
        isLoadingDetail = true
        detailError = nil
        defer { if version == detailVersion { isLoadingDetail = false } }
        do {
            let result = try await membersUseCase.fetchPointHistory(challengerId: target.id)
            guard version == detailVersion, selectedMember?.id == target.id else { return }
            history = result
        } catch {
            guard version == detailVersion, selectedMember?.id == target.id else { return }
            detailError = message(error)
        }
    }

    func grant(type: ChallengerPointType, value: Int, reason: String) async -> Bool {
        guard !isMutating, canManageSelected, let target = selectedMember else { return false }
        do {
            guard availablePointTypes.contains(type) else {
                throw DomainError.custom(message: "이 기수에서는 선택한 유형을 부여할 수 없습니다.")
            }
            try MemberPointValidation.validate(type: type, value: value, description: reason)
            isMutating = true
            actionError = nil
            defer { isMutating = false }
            try await membersUseCase.grantPoint(challengerId: target.id, pointType: type,
                                               pointValue: value,
                                               description: MemberPointValidation.description(reason))
            await didMutate()
            return true
        } catch { actionError = message(error); return false }
    }

    func update(_ item: OperatorMemberPenaltyHistory, reason: String) async -> Bool {
        guard !isMutating, canManageSelected, history.contains(item),
              let id = item.challengerPointId else { return false }
        isMutating = true
        actionError = nil
        defer { isMutating = false }
        do {
            try await useCase.updatePointDescription(pointId: id,
                                                     description: MemberPointValidation.description(reason))
            await didMutate()
            return true
        } catch { actionError = message(error); return false }
    }

    func delete(_ item: OperatorMemberPenaltyHistory) async {
        guard !isMutating, canDeleteSelected, history.contains(item),
              let id = item.challengerPointId else { return }
        isMutating = true
        actionError = nil
        defer { isMutating = false }
        do {
            try await membersUseCase.deletePoint(challengerPointId: id)
            await didMutate()
        } catch { actionError = message(error) }
    }

    private func didMutate() async {
        // 쓰기 성공 후 조회 실패는 별도 오류로 표시하여 중복 부여 재시도를 막습니다.
        NotificationCenter.default.post(name: .memberPenaltyUpdated, object: nil)
        await reloadHistory()
    }

    private func message(_ error: Error) -> String {
        if let error = error as? DomainError { return error.userMessage }
        if let error = error as? AppError { return error.userMessage }
        return "요청을 처리하지 못했어요. 잠시 후 다시 시도해 주세요."
    }
}
