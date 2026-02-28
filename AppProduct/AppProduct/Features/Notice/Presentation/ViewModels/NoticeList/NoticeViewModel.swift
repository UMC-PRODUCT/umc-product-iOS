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

    /// DI Container
    private let container: DIContainer

    /// UseCase
    var noticeUseCase: NoticeUseCaseProtocol {
        container.resolve(NoticeUseCaseProtocol.self)
    }

    /// 기수 Repository
    var genRepository: ChallengerGenRepositoryProtocol {
        container.resolve(ChallengerGenRepositoryProtocol.self)
    }

    /// ViewModel 기능을 extension 파일로 분리해 관리하므로,
    /// 동일 타입 extension에서도 상태 변경이 가능하도록 내부 공개합니다.
    var organizationType: OrganizationType?
    /// 사용자 역할 (역할별 필터/메뉴 가시성 제어에 사용)
    var memberRole: ManagementTeam?
    var chapterId: Int = 0
    var schoolId: Int = 0

    /// 기수-기수ID 쌍 목록
    var gisuPairs: [(gen: Int, gisuId: Int)] = []

    var pagingState = NoticePagingState()
    var userContext: NoticeUserContext = .empty

    /// 기수별 필터 상태 저장소
    var generationStates: [Int: GenerationFilterState] = [:]

    /// 기수 목록
    var generations: [Generation] = []

    /// 선택된 기수
    var selectedGeneration: Generation = Generation(value: 9)

    /// 공지 생성 진입 시 사용할 현재 선택 기수 ID
    var selectedGisuIdForEditor: Int? {
        currentSelectedGisuId()
    }

    /// 공지 데이터 (Loadable)
    var noticeItems: Loadable<[NoticeItemModel]> = .idle

    /// Error Handler
    var errorHandler: ErrorHandler?

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
        self.container = container
    }

    // MARK: - Error Handling

    /// ErrorHandler 바인딩
    func updateErrorHandler(_ handler: ErrorHandler) {
        self.errorHandler = handler
    }

    // MARK: - Helper

    /// 현재 기수의 필터 상태
    var currentState: GenerationFilterState {
        get { generationStates[selectedGeneration.value] ?? GenerationFilterState() }
        set { generationStates[selectedGeneration.value] = newValue }
    }

    /// 현재 선택된 메인필터
    var selectedMainFilter: NoticeMainFilterType {
        currentState.mainFilter
    }

    /// 현재 메인필터의 서브필터 상태
    var currentMainFilterState: MainFilterState {
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

    /// 역할(memberRole) 기반으로 노출할 메인필터 항목 목록을 반환합니다.
    ///
    /// 중앙 운영진은 전체/중앙/지부/학교/파트, 지부장은 지부 이하,
    /// 학교 운영진/챌린저는 학교 이하만 노출됩니다.
    var mainFilterItems: [NoticeMainFilterType] {
        let partItem: [NoticeMainFilterType] = {
            guard let userPart = userContext.part else { return [] }
            return [.part(userPart)]
        }()

        switch memberRole {
        case .superAdmin:
            return []
        case .centralPresident, .centralVicePresident, .centralOperatingTeamMember, .centralEducationTeamMember:
            return [.all, .central, .branch(userContext.branchName), .school(userContext.schoolName)] + partItem
        case .chapterPresident:
            return [.all, .branch(userContext.branchName), .school(userContext.schoolName)] + partItem
        case .schoolPresident, .schoolVicePresident:
            return [.all, .branch(userContext.branchName), .school(userContext.schoolName)] + partItem
        case .schoolPartLeader, .schoolEtcAdmin, .challenger:
            return [.all, .school(userContext.schoolName)] + partItem
        case .none:
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
    }

    /// 현재 메인필터에 따라 노출할 하단 서브필터 칩 목록을 반환합니다.
    ///
    /// - 전체/파트: 칩 없음
    /// - 중앙/지부: 전체 + 파트
    /// - 학교: 학교 + 파트
    var subFilterChips: [NoticeListSubFilterChip] {
        switch selectedMainFilter {
        case .all, .part:
            return []
        case .central:
            return [.all, .part]
        case .branch:
            return [.all, .part]
        case .school:
            return [.school, .part]
        }
    }

    /// 서브필터 표시 여부 (중앙/지부/학교만)
    var showSubFilter: Bool {
        !subFilterChips.isEmpty
    }

    var pageSize: Int {
        Pagination.pageSize
    }

    var pageSort: [String] {
        Pagination.sort
    }
}
