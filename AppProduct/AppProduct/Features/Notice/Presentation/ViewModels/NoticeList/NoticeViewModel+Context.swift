//
//  NoticeViewModel+Context.swift
//  AppProduct
//
//  Created by euijjang97 on 2/17/26.
//

import Foundation

extension NoticeViewModel {

    // MARK: - Context & Filter

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

    // MARK: - Internal Helper

    /// 현재 선택된 gen에 매핑된 gisuId를 반환
    func currentSelectedGisuId() -> Int? {
        gisuPairs.first(where: { $0.gen == selectedGeneration.value })?.gisuId
    }
}
