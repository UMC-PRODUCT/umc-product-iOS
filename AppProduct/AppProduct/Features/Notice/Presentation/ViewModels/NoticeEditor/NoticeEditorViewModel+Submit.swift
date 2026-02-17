//
//  NoticeEditorViewModel+Submit.swift
//  AppProduct
//
//  Created by euijjang97 on 2/17/26.
//

import Foundation

extension NoticeEditorViewModel {

    // MARK: - Save

    /// 수정 화면에서 실제 편집 가능한 값이 변경되었는지 반환합니다.
    var hasEditableChanges: Bool {
        hasBaseContentChanges || hasLinkChanges || hasImageChanges || hasVoteChanges
    }

    /// 공지사항 저장 (생성 or 수정)
    @MainActor
    func saveNotice() async {
        switch mode {
        case .create:
            await createNewNotice()
        case .edit(let noticeId, _):
            await updateExistingNotice(noticeId: noticeId)
        }
    }

    /// 새 공지사항을 생성합니다.
    ///
    /// 이미지 업로드 -> 공지 생성 -> 투표 첨부(선택) 순서로 진행됩니다.
    @MainActor
    func createNewNotice() async {
        createState = .loading

        do {
            let imageIds = try await uploadPendingImagesIfNeeded()
            let targetInfo = buildTargetInfo()
            let links = sanitizedLinksForRequest()

            let notice = try await noticeUseCase.createNotice(
                title: title,
                content: content,
                shouldNotify: allowAlert,
                targetInfo: targetInfo,
                links: links,
                imageIds: imageIds
            )

            if shouldSendVoteRequest, let noticeId = Int(notice.id) {
                _ = try await createVote(noticeId: noticeId)
            }

            createState = .loaded(notice)
            resetForm()
        } catch let error as DomainError {
            createState = .failed(.domain(error))
            handleError(error, action: "createNotice")
        } catch let error as NetworkError {
            createState = .failed(.network(error))
            handleError(error, action: "createNotice")
        } catch {
            createState = .failed(.unknown(message: error.localizedDescription))
            handleError(error, action: "createNotice")
        }
    }

    /// 기존 공지사항을 수정합니다.
    ///
    /// 변경된 필드(제목/내용, 링크, 이미지, 투표)만 선별적으로 API를 호출합니다.
    @MainActor
    func updateExistingNotice(noticeId: Int) async {
        createState = .loading

        do {
            var latestNotice: NoticeDetail?
            var didUpdateAnyField = false

            // 변경 감지된 필드만 개별 API 호출
            if hasBaseContentChanges {
                latestNotice = try await noticeUseCase.updateNotice(
                    noticeId: noticeId,
                    title: title,
                    content: content
                )
                didUpdateAnyField = true
            }

            if hasLinkChanges {
                let links = sanitizedLinksForRequest()
                latestNotice = try await noticeUseCase.updateLinks(
                    noticeId: noticeId,
                    links: links
                )
                didUpdateAnyField = true
            }

            if hasImageChanges {
                _ = try await uploadPendingImagesIfNeeded()
                let imageIds = noticeImages.compactMap(\.fileId)
                latestNotice = try await noticeUseCase.updateImages(
                    noticeId: noticeId,
                    imageIds: imageIds
                )
                didUpdateAnyField = true
            }

            if hasVoteChanges {
                if initialVoteSnapshot != nil {
                    try await noticeUseCase.deleteVote(noticeId: noticeId)
                    didUpdateAnyField = true
                }

                if shouldSendVoteRequest {
                    _ = try await createVote(noticeId: noticeId)
                    didUpdateAnyField = true
                }

                latestNotice = try await noticeUseCase.getDetailNotice(noticeId: noticeId)
            }

            guard didUpdateAnyField else {
                createState = .loaded(
                    try await noticeUseCase.getDetailNotice(noticeId: noticeId)
                )
                return
            }

            if let latestNotice {
                createState = .loaded(latestNotice)
            } else {
                createState = .loaded(
                    try await noticeUseCase.getDetailNotice(noticeId: noticeId)
                )
            }
            alertPrompt = AlertPrompt(
                id: .init(),
                title: "수정 완료",
                message: "공지사항이 수정되었습니다.",
                positiveBtnTitle: "확인"
            )
        } catch let error as DomainError {
            createState = .failed(.domain(error))
            handleError(error, action: "updateNotice")
        } catch let error as NetworkError {
            createState = .failed(.network(error))
            handleError(error, action: "updateNotice")
        } catch {
            createState = .failed(.unknown(message: error.localizedDescription))
            handleError(error, action: "updateNotice")
        }
    }

    /// 공지에 투표를 생성합니다.
    @MainActor
    func createVote(noticeId: Int) async throws -> AddVoteResponseDTO {
        let options = sanitizedVoteOptions()
        let title = voteFormData.title.trimmingCharacters(in: .whitespacesAndNewlines)

        return try await noticeUseCase.addVote(
            noticeId: noticeId,
            title: title,
            isAnonymous: voteFormData.isAnonymous,
            allowMultipleChoice: voteFormData.allowMultipleSelection,
            startsAt: voteFormData.startDate,
            endsAtExclusive: voteFormData.endDate,
            options: options
        )
    }

    /// 공지 생성 API용 TargetInfoDTO를 구성합니다.
    func buildTargetInfo() -> TargetInfoDTO {
        let currentGeneration = resolvedGisuId
        let selectedParts = subCategorySelection.selectedParts.isEmpty
            ? nil
            : Array(subCategorySelection.selectedParts)
        let selectedChapterId = subCategorySelection.selectedBranch?.id
        let selectedSchoolId = subCategorySelection.selectedSchool?.id

        switch selectedCategory {
        case .central:
            return TargetInfoDTO(
                targetGisuId: currentGeneration,
                targetChapterId: selectedChapterId,
                targetSchoolId: selectedSchoolId,
                targetParts: selectedParts
            )
        case .branch:
            return TargetInfoDTO(
                targetGisuId: currentGeneration,
                targetChapterId: resolvedChapterId,
                targetSchoolId: selectedSchoolId,
                targetParts: selectedParts
            )
        case .school:
            return TargetInfoDTO(
                targetGisuId: currentGeneration,
                targetChapterId: nil,
                targetSchoolId: schoolId,
                targetParts: selectedParts
            )
        case .part(let part):
            return TargetInfoDTO(
                targetGisuId: currentGeneration,
                targetChapterId: nil,
                targetSchoolId: nil,
                targetParts: [part]
            )
        }
    }

    /// 에디터 폼 상태를 초기값으로 리셋합니다.
    func resetForm() {
        title = ""
        content = ""
        noticeImages = []
        noticeLinks = []
        voteFormData = VoteFormData()
        isVoteConfirmed = false
        allowAlert = true
    }

    /// 링크 첨부 카드에서 입력된 값 중 실제 전송 가능한 링크만 추출합니다.
    func sanitizedLinksForRequest() -> [String] {
        noticeLinks
            .map { $0.link.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// 제목/내용 변경 여부
    var hasBaseContentChanges: Bool {
        let currentTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseTitle = originalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseContent = originalContent.trimmingCharacters(in: .whitespacesAndNewlines)
        return currentTitle != baseTitle || currentContent != baseContent
    }

    /// 링크 전체 교체 변경 여부
    var hasLinkChanges: Bool {
        let currentLinks = sanitizedLinksForRequest()
        let baseLinks = originalLinks
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return currentLinks != baseLinks
    }

    /// 이미지 전체 교체 변경 여부
    var hasImageChanges: Bool {
        let hasPendingNewImages = noticeImages.contains { $0.fileId == nil }
        if hasPendingNewImages { return true }

        let currentImageIds = noticeImages.compactMap(\.fileId)
        return currentImageIds != originalImageIds
    }

    /// 투표 변경 여부
    var hasVoteChanges: Bool {
        currentVoteSnapshot != initialVoteSnapshot
    }

    /// 현재 화면 상태에서 전송 가능한 투표 스냅샷
    var currentVoteSnapshot: VoteSnapshot? {
        guard shouldSendVoteRequest else { return nil }
        return makeVoteSnapshot(from: voteFormData)
    }

    /// 투표 폼 데이터로 비교 가능한 스냅샷을 생성합니다.
    func makeVoteSnapshot(from form: VoteFormData) -> VoteSnapshot {
        VoteSnapshot(
            title: form.title.trimmingCharacters(in: .whitespacesAndNewlines),
            options: form.options
                .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty },
            isAnonymous: form.isAnonymous,
            allowMultipleSelection: form.allowMultipleSelection,
            startDate: form.startDate,
            endDate: form.endDate
        )
    }

    /// 투표 요청 전송 여부를 판단합니다.
    var shouldSendVoteRequest: Bool {
        guard isVoteConfirmed else { return false }

        let title = voteFormData.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !title.isEmpty && sanitizedVoteOptions().count >= 2
    }

    /// 투표 옵션 입력값 중 실제 전송 가능한 옵션만 추출합니다.
    func sanitizedVoteOptions() -> [String] {
        voteFormData.options
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// 저장 실패를 전역 ErrorHandler로 전달합니다.
    func handleError(_ error: Error, action: String) {
        guard let errorHandler else { return }
        errorHandler.handle(
            error,
            context: ErrorContext(feature: "Notice", action: action)
        )
    }

    /// 저장 시점에만 파일 업로드 플로우를 실행하고 fileId 배열을 반환합니다.
    @MainActor
    func uploadPendingImagesIfNeeded() async throws -> [String] {
        for index in noticeImages.indices {
            guard noticeImages[index].fileId == nil else { continue }
            guard let imageData = noticeImages[index].imageData else { continue }

            noticeImages[index].isLoading = true
            do {
                let fileId = try await noticeUseCase.uploadNoticeAttachmentImage(imageData: imageData)
                noticeImages[index].fileId = fileId
                noticeImages[index].isLoading = false
            } catch {
                noticeImages[index].isLoading = false
                throw error
            }
        }

        return noticeImages.compactMap { $0.fileId }
    }
}

extension NoticeEditorViewModel {
    /// 투표 폼의 비교 가능한 스냅샷 (수정 변경 감지용)
    struct VoteSnapshot: Equatable {
        let title: String
        let options: [String]
        let isAnonymous: Bool
        let allowMultipleSelection: Bool
        let startDate: Date
        let endDate: Date
    }
}
