//
//  NoticeDetailViewModel.swift
//  AppProduct
//
//  Created by 이예지 on 2/2/26.
//

import SwiftUI

/// 공지사항 상세 화면 ViewModel
///
/// 공지 조회/수정/삭제, 투표 처리, 열람 현황(The Ping) 관리를 담당합니다.
@Observable
final class NoticeDetailViewModel {

    // MARK: - Dependency

    /// DI Container
    let container: DIContainer

    /// UseCase
    var noticeUseCase: NoticeUseCaseProtocol {
        container.resolve(NoticeUseCaseProtocol.self)
    }

    var authorizationUseCase: AuthorizationUseCaseProtocol {
        container.resolve(AuthorizationUseCaseProtocol.self)
    }

    // MARK: - Core State

    /// 공지 상세 상태
    var noticeState: Loadable<NoticeDetail>

    /// 액션 메뉴 표시 여부
    var showingActionMenu: Bool = false

    /// Alert 프롬프트
    var alertPrompt: AlertPrompt?

    /// 공지 ID
    let noticeID: Int

    /// 읽음 처리 완료 여부(중복 호출 방지)
    var hasMarkedAsRead: Bool = false

    /// Error Handler
    var errorHandler: ErrorHandler

    /// Navigation 콜백
    var onEditNotice: ((Int) -> Void)?
    var onDeleteSuccess: (() -> Void)?

    // MARK: - Read Status State

    /// 공지 열람 현황 Sheet 표시 여부
    var showReadStatusSheet: Bool = false

    /// 공지 열람 현황 데이터 상태
    var readStatusState: Loadable<NoticeReadStatus> = .idle

    /// 공지 열람 통계 API 원본 값
    var readStatics: NoticeReadStaticsDTO?

    /// 읽음 사용자 페이지 커서
    var readNextCursor: Int?

    /// 안읽음 사용자 페이지 커서
    var unreadNextCursor: Int?

    /// 읽음 사용자 다음 페이지 존재 여부
    var hasNextReadPage: Bool = false

    /// 안읽음 사용자 다음 페이지 존재 여부
    var hasNextUnreadPage: Bool = false

    /// 페이지네이션 진행 상태
    var isLoadingMoreReadStatus: Bool = false

    /// 열람 현황 재시도 진행 상태 (실패 화면의 버튼 내부 로딩 표시용)
    var isRetryingReadStatus: Bool = false

    /// 선택된 탭 (확인/미확인)
    var selectedReadTab: ReadStatusTab = .confirmed

    /// 선택된 필터 타입
    var selectedFilter: ReadStatusFilterType = .all

    // MARK: - Permission State

    /// 공지 수정 가능 여부 (WRITE/MANAGE)
    var canEditNotice: Bool = false

    /// 공지 삭제 가능 여부 (DELETE/MANAGE)
    var canDeleteNotice: Bool = false

    // MARK: - Read Status Computed

    /// 현재 선택된 탭에 따른 필터링된 사용자 목록
    var filteredReadStatusUsers: [ReadStatusUser] {
        guard let readStatus = readStatusState.value else { return [] }
        return selectedReadTab == .confirmed ? readStatus.confirmedUsers : readStatus.unconfirmedUsers
    }

    /// 하단 메시지 표시 여부 (확인 탭에서만)
    var shouldShowBottomMessage: Bool {
        selectedReadTab == .confirmed && readStatusState.value != nil
    }

    /// 하단 메시지 텍스트
    var bottomMessage: String {
        readStatusState.value?.bottomMessage ?? ""
    }

    /// 확인한 인원 수 (버튼용)
    var confirmedCount: Int {
        if let readStatics {
            return Int(readStatics.readCount) ?? 0
        }
        return readStatusState.value?.confirmedCount ?? 0
    }

    /// 확인하지 않은 인원 수 (버튼용)
    var unconfirmedCount: Int {
        if let readStatics {
            return Int(readStatics.unreadCount) ?? 0
        }
        return readStatusState.value?.unconfirmedCount ?? 0
    }

    /// 전체 인원 수 (버튼용)
    var totalCount: Int {
        if let readStatics {
            return Int(readStatics.totalCount) ?? 0
        }
        return readStatusState.value?.totalCount ?? 0
    }

    /// 읽음 비율(0.0 ~ 1.0)
    var readRate: Double {
        if let readStatics {
            return Double(readStatics.readRate) ?? 0
        }

        guard totalCount > 0 else { return 0 }
        return Double(confirmedCount) / Double(totalCount)
    }

    /// 지부별로 그룹화된 사용자
    var groupedUsersByBranch: [String: [ReadStatusUser]] {
        Dictionary(grouping: filteredReadStatusUsers, by: { $0.branch })
            .sorted { $0.key < $1.key }
            .reduce(into: [:]) { $0[$1.key] = $1.value }
    }

    /// 학교별로 그룹화된 사용자
    var groupedUsersBySchool: [String: [ReadStatusUser]] {
        Dictionary(grouping: filteredReadStatusUsers, by: { $0.campus })
            .sorted { $0.key < $1.key }
            .reduce(into: [:]) { $0[$1.key] = $1.value }
    }

    // MARK: - Initialization

    init(
        container: DIContainer,
        errorHandler: ErrorHandler,
        model: NoticeDetail
    ) {
        self.container = container
        self.noticeID = Int(model.id) ?? 0
        self.errorHandler = errorHandler
        self.noticeState = .loaded(model)
    }

    // MARK: - Function

    /// ErrorHandler 업데이트
    func updateErrorHandler(_ handler: ErrorHandler) {
        errorHandler = handler
    }

    /// 액션 메뉴 표시
    func showActionMenu() {
        showingActionMenu = true
    }
}
