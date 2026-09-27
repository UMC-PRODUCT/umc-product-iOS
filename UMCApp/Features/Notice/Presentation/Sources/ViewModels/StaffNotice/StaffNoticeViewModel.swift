//
//  StaffNoticeViewModel.swift
//  NoticePresentation
//
//  Created by 이예지 on 7/22/26.
//

import Foundation
import SwiftUI
import UMCFoundation
import CoreDI
import CoreDomain
import NoticeDomain

// MARK: - StaffNoticeViewModel
/// 운영진 공지 전용 ViewModel
///
/// `NoticeViewModel`과 책임을 분리하여 챌린저/운영진 상태를 격리합니다.
/// 역할 기반 탭 가시성, 탭별 `noticeTab` + `schoolId` 매핑, 페이지네이션을 담당합니다.
@Observable
final class StaffNoticeViewModel {

    // MARK: - Property

    private let container: DIContainer

    private var noticeUseCase: NoticeUseCaseProtocol {
        container.resolve(NoticeUseCaseProtocol.self)
    }

    private var noticeReadRepository: NoticeReadRepositoryProtocol {
        container.resolve(NoticeReadRepositoryProtocol.self)
    }

    private(set) var memberRole: ManagementTeam?
    private(set) var schoolId: String = ""
    private(set) var gisuId: String = ""

    private(set) var accessibleTabs: [StaffNoticeTab] = []
    var selectedTab: StaffNoticeTab?
    private(set) var selectedScope: Scope = .central

    enum Scope: String, CaseIterable, Identifiable {
        case central = "중앙 공지"
        case school = "교내 공지"
        var id: Self { self }
    }

    var availableScopes: [Scope] {
        guard selectedTab != .centralMember, memberRole != .chapterPresident,
              !schoolId.isEmpty, schoolId != "0" else { return [.central] }
        return [.central, .school]
    }

    var noticeItems: Loadable<[NoticeItemModel]> = .idle
    var pagingState = NoticePagingState()
    var hasNoAccessFromServer: Bool = false

    var isSearchMode: Bool = false
    var searchQuery: String = ""

    let errorHandler: ErrorHandler

    private var requestID = UUID()
    private var tabSwitchTask: Task<Void, Never>?

    private enum Pagination {
        static let pageSize: Int = 20
        static let sort: [String] = ["createdAt,DESC"]
    }

    var isLoadingMore: Bool {
        pagingState.isLoadingMore
    }

    // MARK: - Lifecycle

    init(container: DIContainer, errorHandler: ErrorHandler) {
        self.container = container
        self.errorHandler = errorHandler
    }

    // MARK: - Context

    func applyUserContext(
        memberRoleRawValue: String,
        schoolId: String,
        gisuId: String
    ) {
        self.memberRole = ManagementTeam(rawValue: memberRoleRawValue)
        self.schoolId = schoolId
        self.gisuId = gisuId
        self.accessibleTabs = StaffNoticeTab.accessibleTabs(for: memberRole)
        requestID = UUID()
        pagingState.reset()

        if let selectedTab, !accessibleTabs.contains(selectedTab) {
            self.selectedTab = accessibleTabs.first
        } else if selectedTab == nil {
            self.selectedTab = accessibleTabs.first
        }
        if !availableScopes.contains(selectedScope) { selectedScope = .central }
    }

    // MARK: - Tab Selection

    func selectTab(_ tab: StaffNoticeTab) {
        guard accessibleTabs.contains(tab), tab != selectedTab else { return }
        selectedTab = tab
        if !availableScopes.contains(selectedScope) { selectedScope = .central }
        reloadSelection()
    }

    func selectScope(_ scope: Scope) {
        guard availableScopes.contains(scope), scope != selectedScope else { return }
        selectedScope = scope
        reloadSelection()
    }

    private func reloadSelection() {
        requestID = UUID()
        pagingState.reset()
        isSearchMode = false
        searchQuery = ""
        hasNoAccessFromServer = false
        noticeItems = .loading
        tabSwitchTask?.cancel()
        tabSwitchTask = Task { [weak self] in
            await self?.fetchNotices()
        }
    }

    // MARK: - Fetch

    @MainActor
    func fetchNotices(page: Int = 0) async {
        guard let selectedTab else { return }

        if page == 0, hasNoAccessFromServer {
            hasNoAccessFromServer = false
            noticeItems = .loading
        }

        await performPagedFetch(page: page, tab: selectedTab) { request in
            try await self.noticeUseCase.getAllNotices(request: request)
        }
    }

    @MainActor
    func searchNotices(keyword: String, page: Int = 0) async {
        guard !keyword.trimmingCharacters(in: .whitespaces).isEmpty else {
            isSearchMode = false
            await fetchNotices()
            return
        }

        guard let selectedTab else { return }

        isSearchMode = true
        searchQuery = keyword
        await performPagedFetch(page: page, tab: selectedTab) { request in
            try await self.noticeUseCase.searchNotice(keyword: keyword, request: request)
        }
    }

    @MainActor
    func clearSearch() async {
        searchQuery = ""
        isSearchMode = false
        await fetchNotices()
    }

    @MainActor
    func retryCurrentRequest() async {
        if isSearchMode, !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            await searchNotices(keyword: searchQuery)
        } else {
            await fetchNotices()
        }
    }

    @MainActor
    func loadNextPageIfNeeded(currentItem: NoticeItemModel) async {
        guard case .loaded(let items) = noticeItems,
              let last = items.last,
              currentItem.id == last.id,
              pagingState.hasNextPage,
              !pagingState.isLoadingMore else {
            return
        }

        let nextPage = pagingState.nextPage
        if isSearchMode {
            await searchNotices(keyword: searchQuery, page: nextPage)
        } else {
            await fetchNotices(page: nextPage)
        }
    }

    // MARK: - Private

    @MainActor
    private func performPagedFetch(
        page: Int,
        tab: StaffNoticeTab,
        requestAction: (NoticeListRequest) async throws -> NoticePage
    ) async {
        guard !Task.isCancelled else { return }
        if page == 0 {
            requestID = UUID()
            pagingState.reset()
        }
        let currentRequestID = requestID

        let previousState = noticeItems
        if page == 0, noticeItems.value == nil {
            noticeItems = .loading
        }

        guard pagingState.begin(page: page) else { return }

        let request = buildRequest(tab: tab, page: page)

        do {
            let response = try await requestAction(request)
            try Task.checkCancellation()
            guard currentRequestID == requestID else { return }
            applyPagedResponse(response, page: page)
        } catch is CancellationError {
            guard currentRequestID == requestID else { return }
            handleCancelledFetch(page: page, previousState: previousState)
        } catch let error as NSError where error.domain == NSURLErrorDomain
            && error.code == NSURLErrorCancelled {
            guard currentRequestID == requestID else { return }
            handleCancelledFetch(page: page, previousState: previousState)
        } catch let error as RepositoryError {
            guard currentRequestID == requestID else { return }
            handleFetchError(
                .repository(error), page: page, action: "staffFetchNotices", failure: error
            )
        } catch let error as DomainError {
            guard currentRequestID == requestID else { return }
            handleFetchError(
                .domain(error), page: page, action: "staffFetchNotices", failure: error
            )
        } catch let error as NetworkError {
            guard currentRequestID == requestID else { return }
            handleFetchError(
                .network(error), page: page, action: "staffFetchNotices", failure: error
            )
        } catch {
            guard currentRequestID == requestID else { return }
            handleFetchError(
                .unknown(message: error.localizedDescription),
                page: page,
                action: "staffFetchNotices",
                failure: error
            )
        }
    }

    private func buildRequest(tab: StaffNoticeTab, page: Int) -> NoticeListRequest {
        let resolvedSchoolId = selectedScope == .school && availableScopes.contains(.school)
            ? schoolId : nil

        return NoticeListRequest(
            gisuId: gisuId,
            chapterId: nil,
            schoolId: resolvedSchoolId,
            part: nil,
            noticeTab: tab.rawValue,
            page: page,
            size: Pagination.pageSize,
            sort: Pagination.sort
        )
    }

    @MainActor
    private func applyPagedResponse(_ response: NoticePage, page: Int) {
        let readNoticeIDs = resolvedReadNoticeIDs()
        let pairs = (try? container.resolve(ChallengerGenRepositoryProtocol.self)
            .fetchGenGisuIdPairs()) ?? []
        let items = response.items.map { item -> NoticeItemModel in
            var corrected = item
            if let targetGisuId = item.targetGisuId, !targetGisuId.isEmpty, targetGisuId != "0" {
                corrected.targetsAllGenerations = false
                if (Int(item.generation) ?? 0) <= 0 {
                    corrected.generation = pairs.first { $0.gisuId == targetGisuId }?.gen ?? ""
                }
            }
            corrected.isRead = item.isRead || readNoticeIDs.contains(item.noticeId)
            return corrected
        }
        pagingState.applySuccess(page: page, hasNextPage: response.hasNext)

        if page == 0 {
            noticeItems = .loaded(items)
        } else {
            let mergedItems = (noticeItems.value ?? []) + items
            noticeItems = .loaded(mergedItems)
        }
    }

    private func resolvedReadNoticeIDs() -> Set<String> {
        let memberId = AppStorageKey.legacyMemberIdInt()
        guard memberId > 0 else { return [] }
        return (try? noticeReadRepository.fetchReadNoticeIDs(memberId: String(memberId))) ?? []
    }

    @MainActor
    private func handleFetchError(_ error: AppError, page: Int, action: String, failure: Error) {
        if case .network(.requestFailed(let statusCode, _)) = error, statusCode == 403 {
            hasNoAccessFromServer = true
            if page == 0 {
                noticeItems = .loaded([])
            }
            pagingState.applyFailure()
            return
        }

        if page == 0 {
            noticeItems = .failed(error)
        }
        pagingState.applyFailure()

        if case .domain = error { return }

        errorHandler.handle(
            failure,
            context: ErrorContext(feature: "StaffNotice", action: action)
        )
    }

    @MainActor
    private func handleCancelledFetch(page: Int, previousState: Loadable<[NoticeItemModel]>) {
        if page == 0 {
            noticeItems = previousState
        }
        pagingState.applyFailure()
    }
}
