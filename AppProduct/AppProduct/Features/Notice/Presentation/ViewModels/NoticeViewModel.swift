//
//  NoticeViewModel.swift
//  AppProduct
//
//  Created by 이예지 on 1/15/26.
//

import Foundation
import SwiftUI

/// 공지사항 화면 ViewModel
@Observable
final class NoticeViewModel {
    
    // MARK: - Property
    
    /// UseCase
    private let noticeUseCase: NoticeUseCaseProtocol
    
    /// 기수 Repository 추가
    private let genRepository: ChallengerGenRepositoryProtocol
    private var organizationType: OrganizationType?
    private var chapterId: Int = 0
    private var schoolId: Int = 0

    /// 기수-기수ID 쌍 목록
    private(set) var gisuPairs: [(gen: Int, gisuId: Int)] = []
    
    private var pagingState = NoticePagingState()
    private var userContext: NoticeUserContext = .empty
    
    /// 기수 목록
    var generations: [Generation] = []
    
    /// 선택된 기수
    private(set) var selectedGeneration: Generation = Generation(value: 9)
    
    /// 기수별 필터 상태 저장소
    private var generationStates: [Int: GenerationFilterState] = [:]
    
    /// 공지 데이터 (Loadable)
    var noticeItems: Loadable<[NoticeItemModel]> = .idle
    
    /// 페이징 진행 상태 (무한 스크롤 인디케이터 노출용)
    var isLoadingMore: Bool {
        pagingState.isLoadingMore
    }

    /// 검색 관련
    var searchQuery: String = ""
    var isSearchMode: Bool = false

    private enum Pagination {
        static let pageSize: Int = 20
        static let sort: [String] = ["createdAt,DESC"]
    }
    
    // MARK: - Lifecycle
    
    /// 의존성을 주입받아 공지 탭 상태를 초기화합니다.
    init(container: DIContainer) {
        let noticeUseCase = container.resolve(NoticeUseCaseProtocol.self)
        self.noticeUseCase = noticeUseCase

        let genRepository = container.resolve(ChallengerGenRepositoryProtocol.self)
        self.genRepository = genRepository
    }
    
    // MARK: - Helper
    
    /// 현재 기수의 필터 상태
    private var currentState: GenerationFilterState {
        get { generationStates[selectedGeneration.value] ?? GenerationFilterState() }
        set { generationStates[selectedGeneration.value] = newValue }
    }
    
    /// 현재 선택된 메인필터
    var selectedMainFilter: NoticeMainFilterType {
        currentState.mainFilter
    }
    
    /// 현재 메인필터의 서브필터 상태
    private var currentMainFilterState: MainFilterState {
        currentState.state(for: MainFilterKey(from: selectedMainFilter))
    }
    
    /// 현재 선택된 서브필터
    var selectedSubFilter: NoticeSubFilterType {
        currentMainFilterState.subFilter
    }
    
    /// 현재 선택된 파트
    var selectedPart: NoticePart? {
        currentMainFilterState.selectedPart
    }
    
    /// 메인필터 항목 목록
    var mainFilterItems: [NoticeMainFilterType] {
        var items: [NoticeMainFilterType] = [.all]
        if organizationType == .central {
            items.append(.central)
        }
        items.append(.branch(userContext.branchName))
        items.append(.school(userContext.schoolName))
        if let userPart = userContext.part {
            items.append(.part(userPart))
        }
        return items
    }
    
    /// 서브필터 표시 여부 (중앙/지부/학교만)
    var showSubFilter: Bool {
        switch selectedMainFilter {
        case .central, .branch, .school:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Function
    
    /// 공지 탭 메뉴에 쓰이는 사용자 컨텍스트를 반영합니다.
    ///
    /// - Parameters:
    ///   - schoolName: 사용자 학교명
    ///   - chapterName: 사용자 지부명
    ///   - responsiblePart: 사용자 파트 API 값
    ///   - organizationTypeRawValue: 사용자 조직 타입 raw value
    ///   - chapterId: 사용자 지부 ID
    ///   - schoolId: 사용자 학교 ID
    func applyUserContext(
        schoolName: String,
        chapterName: String,
        responsiblePart: String,
        organizationTypeRawValue: String,
        chapterId: Int,
        schoolId: Int
    ) {
        self.userContext = NoticeUserContext(
            schoolName: schoolName,
            chapterName: chapterName,
            responsiblePart: responsiblePart
        )
        self.organizationType = OrganizationType(rawValue: organizationTypeRawValue)
        self.chapterId = chapterId
        self.schoolId = schoolId

        if organizationType != .central, case .central = selectedMainFilter {
            var state = currentState
            state.mainFilter = .all
            currentState = state
        }
    }
    
    /// 기수 목록 조회
    func fetchGisuList() {
        do {
            gisuPairs = try genRepository.fetchGenGisuIdPairs()

            generations = gisuPairs.map { Generation(value: $0.gen) }

            if let latestGen = generations.max(by: { $0.value < $1.value }) {
                selectedGeneration = latestGen

                if generationStates[latestGen.value] == nil {
                    generationStates[latestGen.value] = GenerationFilterState()
                }

                Task {
                    await fetchNotices()
                }
            } else {
                noticeItems = .failed(.domain(.custom(message: "기수 정보를 불러오지 못했습니다.")))
            }
        } catch {
            gisuPairs = []
            generations = []
            noticeItems = .failed(.domain(.custom(message: "기수 정보를 불러오지 못했습니다.")))
        }
    }
    
    /// 기수 선택
    /// - Parameter generation: 선택된 기수
    func selectGeneration(_ generation: Generation) {
        selectedGeneration = generation
        if generationStates[generation.value] == nil {
            generationStates[generation.value] = GenerationFilterState()
        }
        Task {
            await fetchNotices()
        }
    }
    
    /// 메인필터 선택
    /// - Parameter filter: 선택된 메인 필터
    func selectMainFilter(_ filter: NoticeMainFilterType) {
        var state = currentState
        state.mainFilter = filter
        currentState = state
        isSearchMode = false
        searchQuery = ""
        Task {
            await fetchNotices()
        }
    }
    
    /// 서브필터 선택
    /// - Parameter subFilter: 선택된 서브 필터
    func selectSubFilter(_ subFilter: NoticeSubFilterType) {
        let key = MainFilterKey(from: selectedMainFilter)
        var mainState = currentState.state(for: key)
        mainState.subFilter = subFilter
        
        var state = currentState
        state.updateState(for: key, state: mainState)
        currentState = state
        Task {
            await fetchNotices()
        }
    }
    
    /// 파트 선택
    /// - Parameter part: 선택 파트. `nil`이면 파트 전체 의미
    func selectPart(_ part: NoticePart?) {
        let key = MainFilterKey(from: selectedMainFilter)
        var mainState = currentState.state(for: key)
        mainState.selectedPart = part
        
        var state = currentState
        state.updateState(for: key, state: mainState)
        currentState = state
        Task {
            await fetchNotices()
        }
    }
    
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

    /// 현재 선택된 gen에 매핑된 gisuId를 반환
    private func currentSelectedGisuId() -> Int? {
        gisuPairs.first(where: { $0.gen == selectedGeneration.value })?.gisuId
    }

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
            pageSize: Pagination.pageSize,
            sort: Pagination.sort
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
