//
//  NoticeDetailViewModel+NoticeActions.swift
//  AppProduct
//
//  Created by euijjang97 on 2/17/26.
//

import Foundation

extension NoticeDetailViewModel {

    // MARK: - Notice Actions

    /// 공지사항 상세 조회 (최신 데이터 fetch)
    @MainActor
    func fetchNoticeDetail() async {
        if noticeState.isIdle {
            noticeState = .loading
        }

        do {
            let noticeDetail = try await noticeUseCase.getDetailNotice(noticeId: noticeID)
            noticeState = .loaded(noticeDetail)
            isDetailPreparedForEdit = true

        } catch let error as DomainError {
            noticeState = .failed(.domain(error))
        } catch let error as NetworkError {
            noticeState = .failed(.network(error))
        } catch {
            noticeState = .failed(.unknown(message: error.localizedDescription))
        }
    }

    /// 공지 리소스 권한 조회
    @MainActor
    func fetchNoticePermission() async {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--notice-force-permission") {
            canEditNotice = true
            canDeleteNotice = true
            return
        }
        #endif

        do {
            let permission = try await authorizationUseCase.getResourcePermission(
                resourceType: .notice,
                resourceId: noticeID
            )
            canEditNotice = permission.hasAny([.write, .manage])
            canDeleteNotice = permission.hasAny([.delete, .manage])
        } catch {
            let fallback = noticeState.value?.hasPermission ?? false
            canEditNotice = fallback
            canDeleteNotice = fallback
        }
    }

    /// 삭제 확인 다이얼로그 표시
    ///
    /// 확인 버튼 탭 시 화면은 즉시 닫고, 삭제 API는 백그라운드로 전송합니다.
    func showDeleteConfirmation(onDeleteRequested: @escaping () -> Void) {
        alertPrompt = AlertPrompt(
            id: .init(),
            title: "공지 삭제",
            message: "정말 삭제하시겠습니까?",
            positiveBtnTitle: "삭제",
            positiveBtnAction: { [weak self] in
                onDeleteRequested()
                Task {
                    await self?.deleteNotice()
                }
            },
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: true
        )
    }

    /// 공지 상세 진입 시 1회 읽음 처리
    @MainActor
    func markAsReadIfNeeded() async {
        guard !hasMarkedAsRead else { return }
        guard noticeID > 0 else { return }

        do {
            try await noticeUseCase.readNotice(noticeId: noticeID)
            hasMarkedAsRead = true
        } catch {
            // 읽음 처리 실패는 상세 진입을 막지 않습니다.
        }
    }

    /// 리마인더 발송
    @MainActor
    func sendReminder(targetIds: [Int]) async {
        do {
            #if DEBUG
            print("[NoticeReminder] request targetIds: \(targetIds)")
            #endif

            try await noticeUseCase.sendReminder(
                noticeId: noticeID,
                targetIds: targetIds
            )

            let successMessage: String
            if targetIds.count == 1, let singleTargetId = targetIds.first {
                successMessage = "1명에게 리마인더를 발송했습니다. (ID: \(singleTargetId))"
            } else {
                successMessage = "\(targetIds.count)명에게 리마인더를 발송했습니다."
            }

            alertPrompt = AlertPrompt(
                id: .init(),
                title: "리마인더 발송 완료",
                message: successMessage,
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

    /// 미확인 사용자 전체에게 리마인더를 발송합니다.
    ///
    /// 커서 기반 페이징으로 전체 미확인 사용자를 수집한 뒤 일괄 발송합니다.
    @MainActor
    func sendReminderToAllUnreadUsers() async {
        do {
            var cursor = 0
            var hasNext = true
            var targetIds: Set<Int> = []

            // 커서 기반으로 모든 미확인 사용자 ID를 수집
            while hasNext {
                let response = try await fetchReadStatusPage(
                    cursorId: cursor,
                    status: .unconfirmed
                )

                response.content.forEach {
                    if let id = Int($0.challengerId) {
                        targetIds.insert(id)
                    }
                }
                hasNext = response.hasNext
                cursor = parseCursor(response.nextCursor) ?? 0

                // 서버가 빈 커서를 반환하면 무한 루프 방지
                if hasNext && response.nextCursor.isEmpty {
                    break
                }
            }

            await sendReminder(targetIds: Array(targetIds))
        } catch let error as DomainError {
            errorHandler.handle(
                error,
                context: ErrorContext(feature: "Notice", action: "sendReminderToAllUnreadUsers")
            )
        } catch let error as NetworkError {
            errorHandler.handle(
                error,
                context: ErrorContext(feature: "Notice", action: "sendReminderToAllUnreadUsers")
            )
        } catch {
            errorHandler.handle(
                error,
                context: ErrorContext(feature: "Notice", action: "sendReminderToAllUnreadUsers")
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

    /// 투표 응답 처리
    ///
    /// 선택 옵션을 서버로 전송한 뒤 공지 상세를 재조회하여 최신 투표 상태를 반영합니다.
    @MainActor
    func handleVote(voteId: String, optionIds: [String]) async {
        guard case .loaded = noticeState else {
            return
        }
        guard !isSubmittingVote else { return }

        do {
            isSubmittingVote = true
            defer { isSubmittingVote = false }

            guard let resolvedVoteId = Int(voteId) else {
                throw DomainError.custom(message: "유효하지 않은 투표 ID입니다.")
            }

            let resolvedOptionIds = optionIds.compactMap(Int.init)
            guard !resolvedOptionIds.isEmpty else {
                throw DomainError.custom(message: "유효한 투표 항목이 없습니다.")
            }

            try await noticeUseCase.submitVoteResponse(
                voteId: resolvedVoteId,
                optionIds: resolvedOptionIds
            )

            // 서버 반영 결과(득표수/내 선택 상태)를 최신값으로 반영
            let refreshedNotice = try await noticeUseCase.getDetailNotice(noticeId: noticeID)
            noticeState = .loaded(refreshedNotice)
        } catch {
            isSubmittingVote = false
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
                )
            )
        }
    }

    // MARK: - Private

    /// 공지 삭제
    @MainActor
    private func deleteNotice() async {
        do {
            try await noticeUseCase.deleteNotice(noticeId: noticeID)
        } catch let error as DomainError {
            handleDeleteError(error)
        } catch let error as NetworkError {
            handleDeleteError(error)
        } catch {
            handleDeleteError(error)
        }
    }

    /// 삭제 실패 시 ErrorHandler로 에러를 전달하고 재시도 액션을 바인딩합니다.
    private func handleDeleteError(_ error: Error) {
        errorHandler.handle(
            error,
            context: ErrorContext(
                feature: "Notice",
                action: "deleteNotice",
                retryAction: { [weak self] in
                    guard let self = self else { return }
                    Task {
                        await self.deleteNotice()
                    }
                }
            )
        )
    }
}
