//
//  NoticeDetailViewModel.swift
//  AppProduct
//
//  Created by 이예지 on 2/2/26.
//

import SwiftUI

@Observable
final class NoticeDetailViewModel {
    
    /// 공지 상세 상태
    var noticeState: Loadable<NoticeDetail>
    
    /// 액션 메뉴 표시 여부
    var showingActionMenu: Bool = false
    
    /// Alert 프롬프트
    var alertPrompt: AlertPrompt?
    
    /// 공지 ID
    private let noticeID: String
    
    /// Error Handler
    private var errorHandler: ErrorHandler
    
    // MARK: - Read Status Properties
    /// 공지 열람 현황 Sheet 표시 여부
    var showReadStatusSheet: Bool = false
    
    /// 공지 열람 현황 데이터 상태
    var readStatusState: Loadable<NoticeReadStatus> = .idle
    
    /// 선택된 탭 (확인/미확인)
    var selectedReadTab: ReadStatusTab = .confirmed
    
    
    // MARK: - Read Status Computed Properties
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
        readStatusState.value?.confirmedCount ?? 0
    }
    
    /// 확인하지 않은 인원 수 (버튼용)
    var unconfirmedCount: Int {
        readStatusState.value?.unconfirmedCount ?? 0
    }

    /// 전체 인원 수 (버튼용)
    var totalCount: Int {
        readStatusState.value?.totalCount ?? 0
    }
    
    
    // MARK: - Read Status Filter Properties
    /// 선택된 필터 타입
    var selectedFilter: ReadStatusFilterType = .all

    // MARK: - Read Status Grouped Data
    /// 지부별로 그룹화된 사용자
    var groupedUsersByBranch: [String: [ReadStatusUser]] {
        Dictionary(grouping: filteredReadStatusUsers, by: { $0.branch })
            .sorted { $0.key < $1.key }  // 지부명 알파벳 순 정렬
            .reduce(into: [:]) { $0[$1.key] = $1.value }
    }

    /// 학교별로 그룹화된 사용자
    var groupedUsersBySchool: [String: [ReadStatusUser]] {
        Dictionary(grouping: filteredReadStatusUsers, by: { $0.campus })
            .sorted { $0.key < $1.key }  // 학교명 알파벳 순 정렬
            .reduce(into: [:]) { $0[$1.key] = $1.value }
    }
    
    // MARK: - Initialization
    
    init(
        noticeID: String = "1",
        errorHandler: ErrorHandler,
        initialNotice: NoticeDetail? = nil
    ) {
        self.noticeID = noticeID
        self.errorHandler = errorHandler
        
        if let initialNotice = initialNotice {
            self.noticeState = .loaded(initialNotice)
        } else {
            self.noticeState = .loaded(NoticeDetailMockData.sampleNoticeWithPermission)
        }
    }
    
    /// ErrorHandler 업데이트
    func updateErrorHandler(_ handler: ErrorHandler) {
        self.errorHandler = handler
    }
    
    // MARK: - Actions
    
    /// 액션 메뉴 표시
    func showActionMenu() {
        showingActionMenu = true
    }
    
    /// 공지 수정
    func editNotice() {
        // TODO: NoticeEditorView로 이동 - [이예지] 26.02.03
        print("[NoticeDetail] 공지 수정: \(noticeID)")
    }
    
    /// 삭제 확인 다이얼로그 표시
    func showDeleteConfirmation() {
        alertPrompt = AlertPrompt(
            id: .init(),
            title: "공지 삭제",
            message: "정말 삭제하시겠습니까?",
            positiveBtnTitle: "삭제",
            positiveBtnAction: { [weak self] in
                Task {
                    await self?.deleteNotice()
                }
            },
            negativeBtnTitle: "취소"
        )
    }
    
    /// 공지 삭제
    @MainActor
    private func deleteNotice() async {
        // TODO: UseCase로 삭제 처리 - [이예지] 26.02.03
        print("[NoticeDetail] 공지 삭제 시작: \(noticeID)")
        
        do {
            // 삭제 API 호출 시뮬레이션
            try await Task.sleep(nanoseconds: 500_000_000)
            
            // 삭제 성공
            print("[NoticeDetail] 공지 삭제 완료")
            
            // TODO: 이전 화면으로 돌아가기 - [이예지] 26.02.03
        } catch {
            // 삭제 실패 시 에러 처리
            errorHandler.handle(error, context: ErrorContext(
                feature: "Notice",
                action: "deleteNotice",
                retryAction: { [weak self] in
                    guard let self = self else { return }
                    Task {
                        await self.deleteNotice()
                    }
                }
            ))
        }
    }
    
    /// 투표 처리
    @MainActor
    func handleVote(voteId: String, optionIds: [String]) async {
        print("[NoticeDetail] 투표 처리 시작 - Poll ID: \(voteId), Options: \(optionIds)")
        
        // 현재 공지 데이터 가져오기
        guard case .loaded(let currentNotice) = noticeState,
              let currentVote = currentNotice.vote else {
            print("[NoticeDetail] 투표 데이터 없음")
            return
        }
        
        do {
            // 투표 API 호출 시뮬레이션
            try await Task.sleep(nanoseconds: 500_000_000)
            
            // 투표 완료 - 상태 업데이트
            // 1. 투표한 옵션의 voteCount 증가
            let updatedOptions = currentVote.options.map { option in
                if optionIds.contains(option.id) {
                    return VoteOption(
                        id: option.id,
                        title: option.title,
                        voteCount: option.voteCount + 1
                    )
                }
                return option
            }
            
            // 2. 새로운 Vote 생성 (userVotedOptionIds 업데이트)
            let updatedVote = NoticeVote(
                id: currentVote.id,
                question: currentVote.question,
                options: updatedOptions,
                startDate: currentVote.startDate,
                endDate: currentVote.endDate,
                allowMultipleChoices: currentVote.allowMultipleChoices,
                isAnonymous: currentVote.isAnonymous,
                userVotedOptionIds: optionIds
            )
            
            // 3. 새로운 Notice 생성
            let updatedNotice = NoticeDetail(
                id: currentNotice.id,
                generation: currentNotice.generation,
                scope: currentNotice.scope,
                category: currentNotice.category,
                isMustRead: currentNotice.isMustRead,
                title: currentNotice.title,
                content: currentNotice.content,
                authorID: currentNotice.authorID,
                authorName: currentNotice.authorName,
                authorImageURL: currentNotice.authorImageURL,
                createdAt: currentNotice.createdAt,
                updatedAt: currentNotice.updatedAt,
                targetAudience: currentNotice.targetAudience,
                hasPermission: currentNotice.hasPermission,
                images: currentNotice.images,
                links: currentNotice.links,
                vote: updatedVote
            )
            
            // 4. 상태 업데이트
            noticeState = .loaded(updatedNotice)
            
            print("[NoticeDetail] 투표 완료")
        } catch {
            errorHandler.handle(
                error,
                context: ErrorContext(
                    feature: "Notice",
                    action: "handleVote",
                    retryAction: { [weak self] in
                        guard let self = self else { return }
                        Task {
                            await self.handleVote(voteId: voteId, optionIds: optionIds)
                        }
                    }
                ))
        }
    }
    
    
    // MARK: - Read Status Actions
    
    /// 공지 열람 현황 Sheet 표시
    @MainActor
    func openReadStatusSheet() {
        showReadStatusSheet = true
        if readStatusState.isIdle {
            Task { await fetchReadStatus() }
        }
    }
    
    /// 공지 열람 현황 데이터 로드
    @MainActor
    func fetchReadStatus() async {
        readStatusState = .loading
        
        // noticeID에 따라 다른 수신 확인 현황 반환
        let mockReadStatus = NoticeMockData.readStatus(for: noticeID)
        readStatusState = .loaded(mockReadStatus)
    }
    
    /// 탭 전환
    func switchReadTab(to tab: ReadStatusTab) {
        selectedReadTab = tab
    }
}
