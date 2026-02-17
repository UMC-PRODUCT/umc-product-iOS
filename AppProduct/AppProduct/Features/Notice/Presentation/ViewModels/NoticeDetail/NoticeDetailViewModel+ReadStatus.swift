//
//  NoticeDetailViewModel+ReadStatus.swift
//  AppProduct
//
//  Created by euijjang97 on 2/17/26.
//

import Foundation

extension NoticeDetailViewModel {

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
        if let debugState = NoticeDebugState.fromLaunchArgument() {
            switch debugState {
            case .loaded, .loadedCentral, .loadedBranch, .loadedSchool, .loadedPart:
                readStatusState = .loaded(NoticeDetailMockData.sampleReadStatus)
                return
            case .loading, .failed, .detailFailed:
                break
            }
        }
        #endif

        if showLoadingState {
            readStatusState = .loading
        }

        do {
            resetReadStatusPagination()

            let statics = try await noticeUseCase.getReadStatics(noticeId: noticeID)
            readStatics = statics

            let confirmedResponse = try await fetchReadStatusPage(cursorId: 0, status: .confirmed)
            let unconfirmedResponse = try await fetchReadStatusPage(cursorId: 0, status: .unconfirmed)

            let confirmedUsers = confirmedResponse.content.map { $0.toDomain(isRead: true) }
            let unconfirmedUsers = unconfirmedResponse.content.map { $0.toDomain(isRead: false) }

            readNextCursor = parseCursor(confirmedResponse.nextCursor)
            unreadNextCursor = parseCursor(unconfirmedResponse.nextCursor)
            hasNextReadPage = confirmedResponse.hasNext
            hasNextUnreadPage = unconfirmedResponse.hasNext

            readStatusState = .loaded(
                NoticeReadStatus(
                    noticeId: String(noticeID),
                    confirmedUsers: confirmedUsers,
                    unconfirmedUsers: unconfirmedUsers
                )
            )

        } catch let error as DomainError {
            readStatics = nil
            readStatusState = .failed(.domain(error))
        } catch let error as NetworkError {
            readStatics = nil
            readStatusState = .failed(.network(error))
        } catch {
            readStatics = nil
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

    /// 현재 선택된 탭 목록에서 특정 아이템이 하단에 도달했는지 확인하고 다음 페이지를 로드합니다.
    ///
    /// 무한 스크롤 방식으로 리스트 끝 근처 아이템이 표시될 때 자동 호출됩니다.
    @MainActor
    func loadMoreReadStatusIfNeeded(currentItem: ReadStatusUser) async {
        guard var current = readStatusState.value else { return }
        guard !isLoadingMoreReadStatus else { return }

        let currentUsers = selectedReadTab == .confirmed
            ? current.confirmedUsers
            : current.unconfirmedUsers
        guard shouldLoadMore(currentItem: currentItem, in: currentUsers) else { return }

        // 탭별 다음 페이지 존재 여부 및 커서 유효성 확인
        switch selectedReadTab {
        case .confirmed:
            guard hasNextReadPage else { return }
            guard readNextCursor != nil else { return }
        case .unconfirmed:
            guard hasNextUnreadPage else { return }
            guard unreadNextCursor != nil else { return }
        }

        isLoadingMoreReadStatus = true
        defer { isLoadingMoreReadStatus = false }

        do {
            let response = try await fetchReadStatusPage(
                cursorId: selectedReadTab == .confirmed ? (readNextCursor ?? 0) : (unreadNextCursor ?? 0),
                status: selectedReadTab
            )

            let appendedUsers = response.content.map { dto in
                dto.toDomain(isRead: selectedReadTab == .confirmed)
            }

            switch selectedReadTab {
            case .confirmed:
                let merged = current.confirmedUsers + appendedUsers
                current = NoticeReadStatus(
                    noticeId: current.noticeId,
                    confirmedUsers: merged,
                    unconfirmedUsers: current.unconfirmedUsers
                )
                readNextCursor = parseCursor(response.nextCursor)
                hasNextReadPage = response.hasNext
            case .unconfirmed:
                let merged = current.unconfirmedUsers + appendedUsers
                current = NoticeReadStatus(
                    noticeId: current.noticeId,
                    confirmedUsers: current.confirmedUsers,
                    unconfirmedUsers: merged
                )
                unreadNextCursor = parseCursor(response.nextCursor)
                hasNextUnreadPage = response.hasNext
            }

            readStatusState = .loaded(current)
        } catch {
            // 페이징 실패는 기존 데이터를 유지합니다.
        }
    }

    /// 탭 전환
    func switchReadTab(to tab: ReadStatusTab) {
        selectedReadTab = tab
    }

    // MARK: - Read Status Helper

    /// 읽음/안읽음 상세 목록 페이지를 조회합니다.
    func fetchReadStatusPage(
        cursorId: Int,
        status: ReadStatusTab
    ) async throws -> NoticeReadStatusResponseDTO {
        try await noticeUseCase.getReadStatusList(
            noticeId: noticeID,
            cursorId: cursorId,
            filterType: "ALL",
            organizationIds: [],
            status: status == .confirmed ? "READ" : "UNREAD"
        )
    }

    /// 커서 페이지네이션 상태를 초기화합니다.
    func resetReadStatusPagination() {
        readNextCursor = nil
        unreadNextCursor = nil
        hasNextReadPage = false
        hasNextUnreadPage = false
        isLoadingMoreReadStatus = false
    }

    /// 무한 스크롤 트리거 여부를 판단합니다.
    func shouldLoadMore(currentItem: ReadStatusUser, in users: [ReadStatusUser]) -> Bool {
        guard let currentIndex = users.firstIndex(where: { $0.id == currentItem.id }) else {
            return false
        }
        let thresholdIndex = max(users.count - 3, 0)
        return currentIndex >= thresholdIndex
    }

    /// 문자열 커서를 Int로 변환합니다.
    func parseCursor(_ value: String) -> Int? {
        guard !value.isEmpty else { return nil }
        return Int(value)
    }
}
