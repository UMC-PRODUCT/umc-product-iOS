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

    /// 기수 목록
    var generations: [Generation] = []

    /// 현재 기수
    var currentGeneration: Generation = Generation(value: 9)

    /// 선택된 기수
    private(set) var selectedGeneration: Generation = Generation(value: 9)

    /// 기수별 필터 상태 저장소
    private var generationStates: [Int: GenerationFilterState] = [:]

    /// 전체 공지 데이터
    private var allNoticeItems: [NoticeItemModel] = []

    /// 필터링된 공지 데이터
    var noticeItems: Loadable<[NoticeItemModel]> = .idle

    /// 사용자 정보
    var userSchool: String = "가천대학교"
    var userBranch: String = "Nova"
    var userPart: Part = .ios

    // MARK: - Initialization

    init() {
#if DEBUG
        setupMockData()
#endif
    }

    private func setupMockData() {
        generations = (8...12).map { Generation(value: $0) }
        currentGeneration = Generation(value: 9)
        selectedGeneration = Generation(value: 9)
        allNoticeItems = NoticeMockData.items
        generationStates[9] = GenerationFilterState()
        applyFilters()
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

    /// 초기 설정
    func configure(generations: [Generation], current: Generation) {
        self.generations = generations
        self.currentGeneration = current
        self.selectedGeneration = current
        if generationStates[current.value] == nil {
            generationStates[current.value] = GenerationFilterState()
        }
    }

    /// 기수 선택
    func selectGeneration(_ generation: Generation) {
        selectedGeneration = generation
        if generationStates[generation.value] == nil {
            generationStates[generation.value] = GenerationFilterState()
        }
        applyFilters()
    }

    /// 메인필터 선택
    func selectMainFilter(_ filter: NoticeMainFilterType) {
        var state = currentState
        state.mainFilter = filter
        currentState = state
        applyFilters()
    }

    /// 서브필터 선택
    func selectSubFilter(_ subFilter: NoticeSubFilterType) {
        let key = MainFilterKey(from: selectedMainFilter)
        var mainState = currentState.state(for: key)
        mainState.subFilter = subFilter

        var state = currentState
        state.updateState(for: key, state: mainState)
        currentState = state
        applyFilters()
    }

    /// 파트 선택
    func selectPart(_ part: Part) {
        let key = MainFilterKey(from: selectedMainFilter)
        var mainState = currentState.state(for: key)
        mainState.selectedPart = part

        var state = currentState
        state.updateState(for: key, state: mainState)
        currentState = state
        applyFilters()
    }

    // MARK: - Private Methods

    /// 필터 적용
    private func applyFilters() {
        let filtered = allNoticeItems.filter { item in
            // 1. 기수 필터
            guard item.generation == selectedGeneration.value else { return false }

            // 2. 메인필터 (scope/category 매칭)
            guard matchesMainFilter(scope: item.scope, category: item.category) else { return false }

            // 3. 서브필터 (파트 필터링) - 중앙/지부/학교에서만 적용
            guard matchesSubFilter(category: item.category) else { return false }

            return true
        }
        noticeItems = .loaded(filtered)
    }

    /// 메인필터 매칭 검사
    private func matchesMainFilter(scope: NoticeScope, category: NoticeCategory) -> Bool {
        switch selectedMainFilter {
        case .all:
            // 전체: 모든 공지
            return true
        case .central:
            // 중앙: 중앙 일반 + 중앙 파트별
            return scope == .central
        case .branch:
            // 지부: 지부 일반 + 지부 파트별
            return scope == .branch
        case .school:
            // 학교: 교내 일반 + 교내 파트별
            return scope == .campus
        case .part(let filterPart):
            // 파트: 중앙/지부/교내 무관, 해당 파트 공지만
            if case .part(let itemPart) = category {
                return itemPart == filterPart
            }
            return false
        }
    }

    /// 서브필터 매칭 검사 (중앙/지부/학교 메인필터에서만 적용)
    private func matchesSubFilter(category: NoticeCategory) -> Bool {
        // 메인필터가 전체 또는 파트일 경우 서브필터 무시
        guard showSubFilter else { return true }

        // 파트가 선택되어 있으면 항상 파트 필터링 적용
        if selectedPart != .all {
            if case .part(let itemPart) = category {
                return itemPart == selectedPart
            }
            return false
        }

        switch selectedSubFilter {
        case .all:
            // 전체: 해당 scope의 모든 공지 (일반 + 파트별)
            return true
        case .staff:
            // TODO: 운영진 공지 필터링
            return true
        case .part:
            // 파트 서브필터 (파트 기본값): 파트별 공지만 표시 (일반 공지 제외)
            if case .part = category {
                return true
            }
            return false
        }
    }
}
