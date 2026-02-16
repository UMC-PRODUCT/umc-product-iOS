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
    
    // MARK: - Property
    
    /// DI Container
    private let container: DIContainer

    /// UseCase
    private var noticeUseCase: NoticeUseCaseProtocol {
        container.resolve(NoticeUseCaseProtocol.self)
    }
    
    /// 공지 상세 상태
    var noticeState: Loadable<NoticeDetail>
    
    /// 액션 메뉴 표시 여부
    var showingActionMenu: Bool = false
    
    /// Alert 프롬프트
    var alertPrompt: AlertPrompt?
    
    /// 공지 ID
    private let noticeID: Int
    
    /// Error Handler
    private var errorHandler: ErrorHandler
    
    /// Navigation 콜백
    var onEditNotice: ((Int) -> Void)?
    var onDeleteSuccess: (() -> Void)?
    
    // MARK: - Read Status Properties
    /// 공지 열람 현황 Sheet 표시 여부
    var showReadStatusSheet: Bool = false
    
    /// 공지 열람 현황 데이터 상태
    var readStatusState: Loadable<NoticeReadStatus> = .idle
    
    /// 열람 현황 재시도 진행 상태 (실패 화면의 버튼 내부 로딩 표시용)
    var isRetryingReadStatus: Bool = false
    
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
        container: DIContainer,
        errorHandler: ErrorHandler,
        model: NoticeDetail
    ) {
        self.container = container
        self.noticeID = Int(model.id) ?? 0
        self.errorHandler = errorHandler
        self.noticeState = .loaded(model)

        // 공지 진입 시 자동으로 읽음 처리
        Task {
            await markAsRead()
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
    
    /// 공지사항 상세 조회 (최신 데이터 fetch)
    @MainActor
    func fetchNoticeDetail() async {
        if noticeState.isIdle {
            noticeState = .loading
        }

        do {
            let noticeDetail = try await noticeUseCase.getDetailNotice(noticeId: noticeID)
            noticeState = .loaded(noticeDetail)

        } catch let error as DomainError {
            noticeState = .failed(.domain(error))
        } catch let error as NetworkError {
            noticeState = .failed(.network(error))
        } catch {
            noticeState = .failed(.unknown(message: error.localizedDescription))
        }
    }
    
    /// 삭제 확인 다이얼로그 표시
    func showDeleteConfirmation(onDeleteSuccess: @escaping () -> Void) {
        alertPrompt = AlertPrompt(
            id: .init(),
            title: "공지 삭제",
            message: "정말 삭제하시겠습니까?",
            positiveBtnTitle: "삭제",
            positiveBtnAction: { [weak self] in
                Task {
                    await self?.deleteNotice(onSuccess: onDeleteSuccess)
                }
            },
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: true
        )
    }
    
    /// 공지사항 읽음 처리
    @MainActor
    private func markAsRead() async {
        do {
            try await noticeUseCase.readNotice(noticeId: noticeID)
            print("[NoticeDetail] 읽음 처리 완료: \(noticeID)")
        } catch {
            print("[NoticeDetail] 읽음 처리 실패: \(error)")
        }
    }
    
    /// 리마인더 발송
    @MainActor
    func sendReminder(targetIds: [Int]) async {
        do {
            try await noticeUseCase.sendReminder(
                noticeId: noticeID,
                targetIds: targetIds
            )
            
            // 성공 알림
            alertPrompt = AlertPrompt(
                id: .init(),
                title: "리마인더 발송 완료",
                message: "\(targetIds.count)명에게 리마인더를 발송했습니다.",
                positiveBtnTitle: "확인"
            )
            
        } catch let error as DomainError {
            errorHandler.handle(
                error,
                context: ErrorContext(
                    feature: "Notice",
                    action: "sendReminder",
                    retryAction: { [weak self] in
                        guard let self = self else { return }
                        Task {
                            await self.sendReminder(targetIds: targetIds)
                        }
                    }
                )
            )
        } catch {
            errorHandler.handle(
                error,
                context: ErrorContext(
                    feature: "Notice",
                    action: "sendReminder",
                    retryAction: { [weak self] in
                        guard let self = self else { return }
                        Task {
                            await self.sendReminder(targetIds: targetIds)
                        }
                    }
                )
            )
        }
    }
    
    /// 공지 삭제
    @MainActor
    private func deleteNotice(onSuccess: @escaping () -> Void) async {
        print("[NoticeDetail] 공지 삭제 시작: \(noticeID)")

        do {
            try await noticeUseCase.deleteNotice(noticeId: noticeID)

            print("[NoticeDetail] 공지 삭제 완료")

            // 삭제 성공 시 AlertPrompt로 알림 후 화면 닫기
            alertPrompt = AlertPrompt(
                id: .init(),
                title: "삭제 완료",
                message: "공지사항이 삭제되었습니다.",
                positiveBtnTitle: "확인",
                positiveBtnAction: onSuccess
            )

        } catch let error as DomainError {
            errorHandler.handle(
                error,
                context: ErrorContext(
                    feature: "Notice",
                    action: "deleteNotice",
                    retryAction: { [weak self] in
                        guard let self = self else { return }
                        Task {
                            await self.deleteNotice(onSuccess: onSuccess)
                        }
                    }
                )
            )
        } catch let error as NetworkError {
            errorHandler.handle(
                error,
                context: ErrorContext(
                    feature: "Notice",
                    action: "deleteNotice",
                    retryAction: { [weak self] in
                        guard let self = self else { return }
                        Task {
                            await self.deleteNotice(onSuccess: onSuccess)
                        }
                    }
                )
            )
        } catch {
            errorHandler.handle(
                error,
                context: ErrorContext(
                    feature: "Notice",
                    action: "deleteNotice",
                    retryAction: { [weak self] in
                        guard let self = self else { return }
                        Task {
                            await self.deleteNotice(onSuccess: onSuccess)
                        }
                    }
                )
            )
        }
    }
    
    // MARK: - Update Actions
    
    /// 공지사항 수정 완료 (제목, 본문)
    @MainActor
    func updateNoticeContent(title: String, content: String) async {
        noticeState = .loading
        
        do {
            let updatedNotice = try await noticeUseCase.updateNotice(
                noticeId: noticeID,
                title: title,
                content: content
            )
            noticeState = .loaded(updatedNotice)
            
            // 성공 알림
            alertPrompt = AlertPrompt(
                id: .init(),
                title: "수정 완료",
                message: "공지사항이 수정되었습니다.",
                positiveBtnTitle: "확인"
            )
            
        } catch let error as DomainError {
            noticeState = .failed(.domain(error))
        } catch let error as NetworkError {
            noticeState = .failed(.network(error))
        } catch {
            noticeState = .failed(.unknown(message: error.localizedDescription))
        }
    }
    
    /// 공지사항 링크 수정
    @MainActor
    func updateNoticeLinks(links: [String]) async {
        do {
            let updatedNotice = try await noticeUseCase.updateLinks(
                noticeId: noticeID,
                links: links
            )
            noticeState = .loaded(updatedNotice)
            
        } catch {
            errorHandler.handle(
                error,
                context: ErrorContext(
                    feature: "Notice",
                    action: "updateLinks",
                    retryAction: { [weak self] in
                        guard let self = self else { return }
                        Task {
                            await self.updateNoticeLinks(links: links)
                        }
                    }
                )
            )
        }
    }
    
    /// 공지사항 이미지 수정
    @MainActor
    func updateNoticeImages(imageIds: [String]) async {
        do {
            let updatedNotice = try await noticeUseCase.updateImages(
                noticeId: noticeID,
                imageIds: imageIds
            )
            noticeState = .loaded(updatedNotice)
            
        } catch {
            errorHandler.handle(
                error,
                context: ErrorContext(
                    feature: "Notice",
                    action: "updateImages",
                    retryAction: { [weak self] in
                        guard let self = self else { return }
                        Task {
                            await self.updateNoticeImages(imageIds: imageIds)
                        }
                    }
                )
            )
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
    
    /// 공지 열람 현황 데이터 로드 (통계 + 상세)
    @MainActor
    func fetchReadStatus(showLoadingState: Bool = true) async {
        #if DEBUG
        if let debugState = readStatusDebugState {
            switch debugState {
            case .loading:
                if showLoadingState {
                    readStatusState = .loading
                }
            case .loaded:
                readStatusState = .loaded(NoticeDetailMockData.sampleReadStatus)
            case .failed:
                readStatusState = .failed(.unknown(message: "공지 열람 현황 디버그 실패 상태"))
            }
            return
        }

        if isReadStatusMockEnabled {
            readStatusState = .loaded(NoticeDetailMockData.sampleReadStatus)
            return
        }
        #endif

        if showLoadingState {
            readStatusState = .loading
        }

        do {
            // 1. 확인한 사람 목록 조회 (READ)
            let confirmedResponse = try await noticeUseCase.getReadStatusList(
                noticeId: noticeID,
                cursorId: 0,
                filterType: "ALL",
                organizationIds: [],
                status: "READ"
            )

            // 2. 미확인한 사람 목록 조회 (UNREAD)
            let unconfirmedResponse = try await noticeUseCase.getReadStatusList(
                noticeId: noticeID,
                cursorId: 0,
                filterType: "ALL",
                organizationIds: [],
                status: "UNREAD"
            )

            // 3. DTO → 도메인 모델 변환
            let confirmedUsers = confirmedResponse.content.map { dto in
                dto.toDomain(isRead: true)
            }

            let unconfirmedUsers = unconfirmedResponse.content.map { dto in
                dto.toDomain(isRead: false)
            }

            // 4. NoticeReadStatus 생성
            let readStatus = NoticeReadStatus(
                noticeId: String(noticeID),
                confirmedUsers: confirmedUsers,
                unconfirmedUsers: unconfirmedUsers
            )

            readStatusState = .loaded(readStatus)

        } catch let error as DomainError {
            readStatusState = .failed(.domain(error))
        } catch let error as NetworkError {
            readStatusState = .failed(.network(error))
        } catch {
            readStatusState = .failed(.unknown(message: error.localizedDescription))
        }
    }
    
    /// 실패 화면에서 재시도 버튼을 눌렀을 때 호출됩니다.
    @MainActor
    func retryFetchReadStatus() async {
        guard !isRetryingReadStatus else { return }
        isRetryingReadStatus = true
        defer { isRetryingReadStatus = false }
        await fetchReadStatus(showLoadingState: false)
    }
    
    /// 읽음률을 백분율 문자열로 변환합니다. (0.85 → "85%")
    private func formattedReadRate(_ rate: Double) -> String {
        let percentage = Int(rate * 100)
        return "\(percentage)%"
    }
    
    /// 탭 전환
    func switchReadTab(to tab: ReadStatusTab) {
        selectedReadTab = tab
    }

    #if DEBUG
    private enum NoticeReadStatusDebugState: String {
        case loading
        case loaded
        case failed
    }

    /// 스킴 인자 기반 공지 열람 현황 디버그 상태
    ///
    /// 사용 예:
    /// - `-noticeReadStatusDebugState loading`
    /// - `-noticeReadStatusDebugState loaded`
    /// - `-noticeReadStatusDebugState failed`
    private var readStatusDebugState: NoticeReadStatusDebugState? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let stateKeyIndex = arguments.firstIndex(of: "-noticeReadStatusDebugState") else {
            return nil
        }

        let valueIndex = arguments.index(after: stateKeyIndex)
        guard arguments.indices.contains(valueIndex) else {
            return nil
        }

        return NoticeReadStatusDebugState(rawValue: arguments[valueIndex])
    }

    /// 디버그 스킴에서 공지 열람 현황 목 데이터 강제 여부
    private var isReadStatusMockEnabled: Bool {
        let arguments = ProcessInfo.processInfo.arguments
        return arguments.contains("--open-notice-detail-central")
    }
    #endif
}
