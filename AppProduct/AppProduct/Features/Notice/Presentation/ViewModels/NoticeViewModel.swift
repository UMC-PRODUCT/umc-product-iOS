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
    
    // MARK: - Nested Types
    /// 서브필터 타입 (ViewModel 내부용)
    enum SubFilterType: Equatable {
        case all
        case management
    }
    
    // MARK: - Properties
    /// 기수 목록
    var generations: [Generation] = [
        Generation(value: 8),
        Generation(value: 9),
        Generation(value: 10),
        Generation(value: 11),
        Generation(value: 12)
    ]
    /// 현재 기수
    var currentGeneration: Generation = Generation(value: 9)
    /// 선택된 기수
    var selectedGeneration: Generation = Generation(value: 9)

    /// 메인필터 선택값
    var selectedNoticeMainFilter: NoticeMainFilterType = .all
    /// 서브필터 선택값
    var selectedNoticeSubFilter: NoticeSubFilterType = .all
    /// 파트 선택값
    var selectedPart: Part? = .all
    /// 필터 시트 표시 여부
    var isShowingFilterSheet: Bool = false

    /// 메인필터별 서브필터 상태
    var centralSubFilter: SubFilterType = .all
    var branchSubFilter: SubFilterType = .all
    var schoolSubFilter: SubFilterType = .all

    var noticeItems: Loadable<[NoticeItemModel]> = .idle
    
    private var allNoticeItems: [NoticeItemModel] = []
    
    init() {
#if DEBUG
        setupMockData()
#endif
    }
   
    private func setupMockData() {
        generations = (8...12).map { Generation(value: $0) }
        currentGeneration = Generation(value: 9)
        selectedGeneration = Generation(value: 9)
        noticeItems = .loaded(NoticeItemModel.mockItems)
    }
    
    /// 사용자 정보
    var userSchool: String = "가천대학교"
    var userBranch: String = "Nova"
    var userPart: Part = .ios

    // MARK: - Computed Properties
    /// 현재 메인필터에 해당하는 서브필터 상태
    var currentSubFilter: SubFilterType {
        switch selectedNoticeMainFilter {
        case .central: return centralSubFilter
        case .branch: return branchSubFilter
        case .school: return schoolSubFilter
        default: return .all
        }
    }

    /// 메인필터 항목 목록
    var mainFilterItems: [NoticeMainFilterType] {
        [
            .all,
            .central,
            .branch(userBranch),
            .school(userSchool),
            .part(userPart)
        ]
    }

    // MARK: - Methods
    /// 초기 설정
    func configure(generations: [Generation], current: Generation) {
        self.generations = generations
        self.currentGeneration = current
        self.selectedGeneration = current
    }
    
    /// 필터 적용 메서드
    private func applyFilters() {
        let filtered = allNoticeItems.filter { item in
            item.generation == selectedGeneration.value
        }
        noticeItems = .loaded(filtered)
    }
    
    /// 기수 선택 메서드
    func selectGeneration(_ generation: Generation) {
        selectedGeneration = generation
        applyFilters()
    }

    /// 메인필터 선택
    func selectMainFilter(_ filter: NoticeMainFilterType) {
        selectedNoticeMainFilter = filter
        switch filter {
        case .central, .branch, .school:
            isShowingFilterSheet = true
        case .all, .part:
            break
        }
    }

    /// 서브필터 선택
    func selectSubFilter(_ subFilter: SubFilterType) {
        switch selectedNoticeMainFilter {
        case .central: centralSubFilter = subFilter
        case .branch: branchSubFilter = subFilter
        case .school: schoolSubFilter = subFilter
        default: break
        }
    }
}

    
