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
    
    // MARK: - Properties
    
    /// UseCase
    private let noticeUseCase: NoticeUseCaseProtocol
    
    /// 기수 Repository 추가
    private let genRepository: ChallengerGenRepositoryProtocol
    
    /// UserDefaults 접근 - 사용자 조직 정보 (computed properties)
    private var organizationId: Int {
        UserDefaults.standard.integer(forKey: AppStorageKey.organizationId)
    }

    private var schoolId: Int {
        UserDefaults.standard.integer(forKey: AppStorageKey.schoolId)
    }

    /// 기수-기수ID 쌍 목록
    private(set) var gisuPairs: [(gen: Int, gisuId: Int)] = []
    
    /// ErrorHandler
    private var errorHandler: ErrorHandler?
    
    /// 기수 목록
    var generations: [Generation] = []
    
    /// 현재 기수
    var currentGeneration: Generation = Generation(value: 9)
    
    /// 선택된 기수
    private(set) var selectedGeneration: Generation = Generation(value: 9)
    
    /// 기수별 필터 상태 저장소
    private var generationStates: [Int: GenerationFilterState] = [:]
    
    /// 공지 데이터 (Loadable)
    var noticeItems: Loadable<[NoticeItemModel]> = .idle
    
    /// 사용자 정보
    var userSchool: String = "가천대학교"
    var userBranch: String = "Nova"
    var userPart: Part = .ios
    
    /// 페이징 정보
    private var currentPage: Int = 0
    private var hasNextPage: Bool = false

    /// 검색 관련
    var searchQuery: String = ""
    var isSearchMode: Bool = false
    
    // MARK: - Initialization
    
    init(container: DIContainer) {
        let noticeUseCase = container.resolve(NoticeUseCaseProtocol.self)
        self.noticeUseCase = noticeUseCase

        let genRepository = container.resolve(ChallengerGenRepositoryProtocol.self)
        self.genRepository = genRepository
    }
    
    // MARK: - Computed Properties (현재 기수 상태)
    
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
    var selectedPart: Part {
        currentMainFilterState.selectedPart
    }
    
    /// 메인필터 항목 목록
    var mainFilterItems: [NoticeMainFilterType] {
        [.all, .central, .branch(userBranch), .school(userSchool), .part(userPart)]
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
    
    // MARK: - Actions
    
    /// ErrorHandler 업데이트
    func updateErrorHandler(_ handler: ErrorHandler) {
        self.errorHandler = handler
    }
    
    /// 기수 목록 조회
    func fetchGisuList() {
        do {
            gisuPairs = try genRepository.fetchGenGisuIdPairs()

            // Generation 객체로 변환
            generations = gisuPairs.map { Generation(value: $0.gen) }

            // 현재 기수 설정 (가장 최신 기수)
            if let latestGen = generations.max(by: { $0.value < $1.value }) {
                currentGeneration = latestGen
                selectedGeneration = latestGen

                // 선택된 기수의 상태 초기화
                if generationStates[latestGen.value] == nil {
                    generationStates[latestGen.value] = GenerationFilterState()
                }
            }
        } catch {
            // 오류 발생 시 빈 배열
            gisuPairs = []
            generations = []
        }
    }
    
    /// 기수 선택
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
    func selectMainFilter(_ filter: NoticeMainFilterType) {
        var state = currentState
        state.mainFilter = filter
        currentState = state
        Task {
            await fetchNotices()
        }
    }
    
    /// 서브필터 선택
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
    func selectPart(_ part: Part) {
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
    
    // MARK: - API Methods
    
    /// 공지사항 목록 조회
    @MainActor
    func fetchNotices(page: Int = 0) async {
        noticeItems = .loading
        currentPage = page
        
        do {
            let request = buildNoticeListRequest(page: page)
            let response = try await noticeUseCase.getAllNotices(request: request)
            let items = response.content.map { $0.toItemModel() }
            
            hasNextPage = response.hasNext
            noticeItems = .loaded(items)
            
        } catch let error as DomainError {
            noticeItems = .failed(.domain(error))
        } catch let error as NetworkError {
            noticeItems = .failed(.network(error))
        } catch {
            noticeItems = .failed(.unknown(message: error.localizedDescription))
        }
    }
    
    /// 공지사항 검색
    @MainActor
    func searchNotices(keyword: String, page: Int = 0) async {
        guard !keyword.trimmingCharacters(in: .whitespaces).isEmpty else {
            // 빈 검색어면 일반 목록으로 전환
            isSearchMode = false
            await fetchNotices()
            return
        }

        noticeItems = .loading
        currentPage = page
        isSearchMode = true
        searchQuery = keyword

        do {
            let request = buildNoticeListRequest(page: page)
            let response = try await noticeUseCase.searchNotice(
                keyword: keyword,
                request: request
            )
            let items = response.content.map { $0.toItemModel() }

            hasNextPage = response.hasNext
            noticeItems = .loaded(items)

        } catch let error as DomainError {
            noticeItems = .failed(.domain(error))
        } catch let error as NetworkError {
            noticeItems = .failed(.network(error))
        } catch {
            noticeItems = .failed(.unknown(message: error.localizedDescription))
        }
    }
    
    /// 검색 모드 해제 (일반 목록으로 복귀)
    @MainActor
    func clearSearch() async {
        searchQuery = ""
        isSearchMode = false
        await fetchNotices()
    }
    
    // MARK: - Private Helpers
    
    /// NoticeListRequestDTO 생성
    private func buildNoticeListRequest(page: Int) -> NoticeListRequestDTO {
        let requestChapterId: Int? = organizationId > 0 ? organizationId : nil
        let requestSchoolId: Int? = schoolId > 0 ? schoolId : nil
        
        // 메인 필터에 따른 파트 결정
        let part: UMCPartType? = {
            switch selectedMainFilter {
            case .part(let filterPart):
                return filterPart.toUMCPartType()
            default:
                // 서브필터에서 파트 선택된 경우
                if selectedPart != .all {
                    return selectedPart.toUMCPartType()
                }
                return nil
            }
        }()
        
        return NoticeListRequestDTO(
            gisuId: selectedGeneration.value,
            chapterId: requestChapterId,
            schoolId: requestSchoolId,
            part: part,
            page: page,
            size: 20,
            sort: ["createdAt,DESC"]
        )
    }
}
