//
//  NoticeViewModel+Fetch.swift
//  AppProduct
//
//  Created by euijjang97 on 2/17/26.
//

import Foundation

extension NoticeViewModel {

    // MARK: - Fetch

    /// 공지사항 목록 조회
    /// - Parameter page: 조회할 페이지 인덱스
    @MainActor
    func fetchNotices(page: Int = 0) async {
        await performPagedFetch(page: page) { request in
            try await self.noticeUseCase.getAllNotices(request: request)
        }
    }

    /// 공지사항 검색
    ///
    /// - Parameters:
    ///   - keyword: 검색어
    ///   - page: 조회할 페이지 인덱스
    @MainActor
    func searchNotices(keyword: String, page: Int = 0) async {
        guard !keyword.trimmingCharacters(in: .whitespaces).isEmpty else {
            isSearchMode = false
            await fetchNotices()
            return
        }

        isSearchMode = true
        searchQuery = keyword
        await performPagedFetch(page: page) { request in
            try await self.noticeUseCase.searchNotice(keyword: keyword, request: request)
        }
    }

    /// 검색 모드 해제 (일반 목록으로 복귀)
    @MainActor
    func clearSearch() async {
        searchQuery = ""
        isSearchMode = false
        await fetchNotices()
    }

    /// 현재 상태 기준으로 공지 조회를 재시도합니다.
    /// - Note: 기수 매핑이 비어 있으면 기수 목록부터 다시 로드합니다.
    @MainActor
    func retryCurrentRequest() async {
        if gisuPairs.isEmpty {
            fetchGisuList()
            return
        }

        if isSearchMode, !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            await searchNotices(keyword: searchQuery)
        } else {
            await fetchNotices()
        }
    }

    /// 리스트 마지막 셀 진입 시 다음 페이지 로드
    /// - Parameter currentItem: 화면에 노출된 현재 항목
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

    // MARK: - Private Function

    /// 페이징 조회 공통 로직 (기수 검증 → 요청 → 응답 반영)
    @MainActor
    private func performPagedFetch(
        page: Int,
        requestAction: (NoticeListRequestDTO) async throws -> NoticePageDTO<NoticeDTO>
    ) async {
        guard let gisuId = preparePagingAndResolveGisuId(page: page) else { return }

        do {
            let request = buildNoticeListRequest(gisuId: gisuId, page: page)
            let response = try await requestAction(request)
            applyPagedResponse(response, page: page)
        } catch let error as DomainError {
            handleFetchError(.domain(error), page: page)
        } catch let error as NetworkError {
            handleFetchError(.network(error), page: page)
        } catch {
            handleFetchError(.unknown(message: error.localizedDescription), page: page)
        }
    }

    /// 페이지 상태를 준비하고 현재 선택된 기수의 gisuId를 반환합니다.
    /// - Parameter page: 요청 페이지
    /// - Returns: 조회 가능한 gisuId. 없으면 `nil`
    @MainActor
    private func preparePagingAndResolveGisuId(page: Int) -> Int? {
        if page == 0 {
            noticeItems = .loading
        }
        guard pagingState.begin(page: page) else { return nil }

        guard let gisuId = currentSelectedGisuId() else {
            handleFetchError(.domain(.custom(message: "기수 정보를 불러오지 못했습니다.")), page: page)
            return nil
        }
        return gisuId
    }

    /// 페이지 응답을 목록 상태에 반영합니다.
    /// - Parameters:
    ///   - response: 공지 페이징 응답 DTO
    ///   - page: 조회한 페이지 인덱스
    @MainActor
    private func applyPagedResponse(_ response: NoticePageDTO<NoticeDTO>, page: Int) {
        let items = response.content.map { $0.toItemModel() }
        pagingState.applySuccess(page: page, hasNextPage: response.hasNext)

        if page == 0 {
            noticeItems = .loaded(items)
        } else {
            let mergedItems = (noticeItems.value ?? []) + items
            noticeItems = .loaded(mergedItems)
        }
    }

    /// 조회 실패 상태를 반영합니다.
    /// - Parameters:
    ///   - error: 화면에 표시할 앱 에러
    ///   - page: 실패한 페이지 인덱스
    @MainActor
    private func handleFetchError(_ error: AppError, page: Int) {
        if page == 0 {
            noticeItems = .failed(error)
        }
        pagingState.applyFailure()
    }

    /// NoticeListRequestDTO 생성
    private func buildNoticeListRequest(gisuId: Int, page: Int) -> NoticeListRequestDTO {
        NoticeRequestFactory.make(
            gisuId: gisuId,
            page: page,
            selectedMainFilter: selectedMainFilter,
            selectedPart: selectedPart,
            organizationType: organizationType,
            chapterId: chapterId,
            schoolId: schoolId,
            pageSize: pageSize,
            sort: pageSort
        )
    }

#if DEBUG
    /// 디버그 스킴 상태를 빠르게 재현하기 위한 시드 데이터 주입 함수입니다.
    func seedForDebugState(
        noticeItems: Loadable<[NoticeItemModel]>,
        mainFilter: NoticeMainFilterType,
        generations: [Generation] = [Generation(value: 9)],
        selectedGeneration: Generation = Generation(value: 9),
        subFilter: NoticeSubFilterType = .all,
        selectedPart: NoticePart? = nil
    ) {
        self.generations = generations
        self.selectedGeneration = selectedGeneration
        self.noticeItems = noticeItems
        self.searchQuery = ""
        self.isSearchMode = false
        pagingState.reset()

        let key = MainFilterKey(from: mainFilter)
        var state = GenerationFilterState()
        state.mainFilter = mainFilter
        state.updateState(
            for: key,
            state: MainFilterState(subFilter: subFilter, selectedPart: selectedPart)
        )
        generationStates[selectedGeneration.value] = state
    }
#endif
}
