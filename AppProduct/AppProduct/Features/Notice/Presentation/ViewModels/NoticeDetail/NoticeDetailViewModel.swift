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

    /// 작성자 프로필 조회용 MyPage Repository
    var myPageRepository: MyPageRepositoryProtocol {
        container.resolve(MyPageRepositoryProtocol.self)
    }

    var authorizationUseCase: AuthorizationUseCaseProtocol {
        container.resolve(AuthorizationUseCaseProtocol.self)
    }

    // MARK: - Core State

    /// 공지 상세 상태
    var noticeState: Loadable<NoticeDetail>

    /// 작성자 표시 텍스트 (닉네임/이름-기수TH UMC 직책)
    var authorDisplayName: String = ""

    /// 액션 메뉴 표시 여부
    var showingActionMenu: Bool = false

    /// Alert 프롬프트
    var alertPrompt: AlertPrompt?

    /// 투표 응답 전송 진행 상태
    var isSubmittingVote: Bool = false

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

    /// 공지 열람 통계(read-statics) 로딩 상태
    var isReadStaticsLoading: Bool = false

    /// 공지 열람 통계 선조회 여부
    var hasPrefetchedReadStatics: Bool = false

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

    /// 수정 화면 진입에 필요한 상세 데이터 준비 완료 여부
    var isDetailPreparedForEdit: Bool = false

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
        authorDisplayName = model.authorName
        Task { [weak self] in
            self?.refreshAuthorDisplayName(for: model)
        }
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

    // MARK: - Author Profile

    /// 공지 작성자의 멤버 프로필을 조회하여 "닉네임/이름-기수TH UMC 직책" 형식의 표시명을 갱신합니다.
    ///
    /// `authorMemberId`가 유효한 경우 비동기로 프로필 API를 호출하고,
    /// 실패 시 `defaultAuthorDisplayName`을 폴백으로 사용합니다.
    @MainActor
    func refreshAuthorDisplayName(for detail: NoticeDetail) {
        let fallback = detail.defaultAuthorDisplayName
        authorDisplayName = fallback

        guard
            let rawMemberId = detail.authorMemberId,
            let memberId = Int(rawMemberId),
            memberId > 0
        else {
            return
        }

        Task {
            await loadAuthorDisplayName(memberId: memberId, fallback: fallback)
        }
    }

    /// 멤버 프로필 API를 호출하여 작성자 표시명을 비동기 로드합니다.
    @MainActor
    private func loadAuthorDisplayName(memberId: Int, fallback: String) async {
        do {
            let profile = try await myPageRepository.fetchMemberProfile(memberId: memberId)
            authorDisplayName = buildAuthorDisplayName(
                nickname: profile.nickname,
                name: profile.name,
                generation: profile.generation,
                roleName: profile.roleName,
                fallback: fallback
            )
        } catch {
            errorHandler.handle(
                error,
                context: ErrorContext(
                    feature: "Notice",
                    action: "loadAuthorDisplayName(memberId:\(memberId))"
                )
            )
            authorDisplayName = fallback
        }
    }

    /// "닉네임/이름-기수TH UMC 직책" 형식의 작성자 표시명을 조합합니다.
    private func buildAuthorDisplayName(
        nickname: String,
        name: String,
        generation: Int,
        roleName: String,
        fallback: String
    ) -> String {
        let cleanedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedNickname.isEmpty || !cleanedName.isEmpty else {
            return fallback
        }

        let identity = "\(cleanedNickname)/\(cleanedName)"
        let generationText = authorGenerationText(from: generation)
        let roleText = roleName.trimmingCharacters(in: .whitespacesAndNewlines)

        if roleText.isEmpty {
            return identity.isEmpty ? fallback : "\(identity)-\(generationText) 참여자"
        }
        return identity.isEmpty ? fallback : "\(identity)-\(generationText) \(roleText)"
    }

    /// 기수 숫자를 "NTH UMC" 형식의 문자열로 변환합니다.
    private func authorGenerationText(from generation: Int) -> String {
        guard generation > 0 else {
            return "UMC"
        }
        return "\(generation)\(generationOrdinalSuffix(generation)) UMC"
    }

    /// 영어 서수 접미사를 반환합니다 (1st, 2nd, 3rd, 4th...).
    private func generationOrdinalSuffix(_ value: Int) -> String {
        let suffixBase = value % 100
        if (11...13).contains(suffixBase) {
            return "th"
        }

        switch value % 10 {
        case 1:
            return "st"
        case 2:
            return "nd"
        case 3:
            return "rd"
        default:
            return "th"
        }
    }
}
