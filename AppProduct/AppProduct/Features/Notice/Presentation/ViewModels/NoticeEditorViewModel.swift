//
//  NoticeEditorViewModel.swift
//  AppProduct
//
//  Created by 이예지 on 1/24/26.
//

import Foundation
import SwiftUI
import PhotosUI
import UIKit

/// 공지사항 에디터 ViewModel
///
/// 공지 생성/수정, 카테고리/타겟 선택, 이미지/링크/투표 첨부 상태를 관리합니다.
@Observable
final class NoticeEditorViewModel: MultiplePhotoPickerManageable {

    // MARK: - Dependency

    private let noticeUseCase: NoticeUseCaseProtocol
    private let targetUseCase: NoticeEditorTargetUseCaseProtocol
    private var errorHandler: ErrorHandler?

    // MARK: - Mode

    /// 편집 모드 (생성 or 수정)
    private let mode: NoticeEditorMode

    // MARK: - User Context

    private var gisuId: Int {
        UserDefaults.standard.integer(forKey: AppStorageKey.gisuId)
    }

    private var organizationId: Int {
        UserDefaults.standard.integer(forKey: AppStorageKey.organizationId)
    }

    private var schoolId: Int {
        UserDefaults.standard.integer(forKey: AppStorageKey.schoolId)
    }

    /// 뷰에서 전달받는 사용자 컨텍스트(우선 적용)
    private var userGisuId: Int?
    private var userChapterId: Int?

    private var resolvedGisuId: Int {
        userGisuId ?? gisuId
    }

    private var resolvedChapterId: Int {
        userChapterId ?? organizationId
    }

    // MARK: - View State

    /// 공지 생성/수정 상태
    private(set) var createState: Loadable<NoticeDetail> = .idle

    /// 선택된 메인 카테고리
    var selectedCategory: EditorMainCategory {
        didSet {
            if oldValue != selectedCategory {
                subCategorySelection = EditorSubCategorySelection()
            }
        }
    }

    /// 서브카테고리 선택 상태
    var subCategorySelection = EditorSubCategorySelection()

    /// 공지 타겟(지부, 학교, 파트) 시트 표시 여부
    var activeSheetType: TargetSheetType?

    /// 사용자 조직 타입에 따라 노출 가능한 메인 카테고리 목록
    var availableCategories: [EditorMainCategory]

    /// 지부 선택 시트 목록 (중앙 선택 시)
    var branchOptions: [NoticeTargetOption] = []

    /// 학교 선택 시트 목록
    var schoolOptions: [NoticeTargetOption] = []

    /// 공지사항 제목
    var title: String = ""

    /// 공지사항 본문
    var content: String = ""

    /// 투표 폼 시트 표시 여부
    var showVoting: Bool = false

    /// 투표 폼 데이터
    var voteFormData: VoteFormData = VoteFormData()

    /// 투표 확정 여부
    var isVoteConfirmed: Bool = false

    /// 화면 AlertPrompt
    var alertPrompt: AlertPrompt?

    /// PhotosPicker 선택 아이템
    var selectedPhotoItems: [PhotosPickerItem] = []

    /// 로드된 UIImage 목록
    var selectedImages: [UIImage] = []

    /// 첨부 이미지 카드 목록
    var noticeImages: [NoticeImageItem] = []

    /// 첨부 링크 카드 목록
    var noticeLinks: [NoticeLinkItem] = []

    /// 알림 발송 여부
    var allowAlert: Bool = true

    // MARK: - Edit Snapshot

    /// 수정 화면 원본 제목
    private var originalTitle: String = ""

    /// 수정 화면 원본 본문
    private var originalContent: String = ""

    /// 수정 화면 원본 링크 목록
    private var originalLinks: [String] = []

    /// 수정 화면 원본 투표 폼
    private var originalVoteFormData: VoteFormData?

    // MARK: - Derived State

    /// 수정 모드 여부
    var isEditMode: Bool {
        if case .edit = mode {
            return true
        }
        return false
    }

    /// 저장 가능 여부
    ///
    /// 생성: 제목/내용 필수
    /// 수정: 제목/내용 필수 + 실제 변경사항 존재
    var canSubmit: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasRequiredFields = !trimmedTitle.isEmpty && !trimmedContent.isEmpty

        switch mode {
        case .create:
            return hasRequiredFields
        case .edit:
            return hasRequiredFields && hasEditableChanges
        }
    }

    /// 수정 화면에서 실제 편집 가능한 값이 변경되었는지 반환합니다.
    private var hasEditableChanges: Bool {
        let currentTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseTitle = originalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseContent = originalContent.trimmingCharacters(in: .whitespacesAndNewlines)

        if currentTitle != baseTitle { return true }
        if currentContent != baseContent { return true }

        let currentLinks = noticeLinks.map { $0.link.trimmingCharacters(in: .whitespacesAndNewlines) }
        let baseLinks = originalLinks.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        if currentLinks != baseLinks { return true }

        // 수정 모드에서는 "새로 추가한 이미지"만 반영하므로 비어있지 않으면 변경으로 간주
        if !noticeImages.isEmpty { return true }

        return false
    }

    // MARK: - Initializer

    init(
        container: DIContainer,
        mode: NoticeEditorMode = .create
    ) {
        self.noticeUseCase = container.resolve(NoticeUseCaseProtocol.self)
        self.targetUseCase = container.resolve(NoticeEditorTargetUseCaseProtocol.self)
        self.mode = mode

        let categories: [EditorMainCategory] = [.branch, .school]
        self.availableCategories = categories
        self.selectedCategory = categories.first ?? .branch

        if case .edit(_, let notice) = mode {
            loadNoticeForEdit(notice)
        }
    }

    // MARK: - Public Action

    /// 조직 타입 기준으로 메인 카테고리 목록을 갱신합니다.
    func applyOrganizationType(_ organizationTypeRawValue: String) {
        let organizationType = OrganizationType(rawValue: organizationTypeRawValue)
        let categories = Self.availableCategories(for: organizationType)

        if categories != availableCategories {
            availableCategories = categories
        }

        if !availableCategories.contains(selectedCategory) {
            selectedCategory = availableCategories.first ?? .branch
        }

        Task {
            await loadTargetOptions()
        }
    }

    /// 뷰에서 사용자 컨텍스트(AppStorage)를 전달받아 반영합니다.
    func updateUserContext(gisuId: Int, chapterId: Int) {
        userGisuId = gisuId
        userChapterId = chapterId

        Task { @MainActor in
            await loadTargetOptions()
        }
    }
    
    /// View 계층의 ErrorHandler를 바인딩합니다.
    func updateErrorHandler(_ handler: ErrorHandler) {
        errorHandler = handler
    }

    /// 현재 메인 카테고리에 맞는 타겟 목록을 조회합니다.
    @MainActor
    func loadTargetOptions() async {
        do {
            switch selectedCategory {
            case .central:
                async let branches = targetUseCase.fetchAllBranches()
                async let schools = targetUseCase.fetchAllSchools()
                branchOptions = try await branches
                schoolOptions = try await schools
            case .branch:
                branchOptions = []
                schoolOptions = try await targetUseCase.fetchSchools(
                    inChapterId: resolvedChapterId,
                    gisuId: resolvedGisuId
                )
            case .school, .part:
                branchOptions = []
                schoolOptions = []
            }
        } catch {
            // 조회 실패 시에도 빈 화면을 피하기 위해 Mock 데이터로 폴백
            switch selectedCategory {
            case .central:
                branchOptions = EditorMockData.branches
                schoolOptions = EditorMockData.schools
            case .branch:
                branchOptions = []
                schoolOptions = EditorMockData.chapterSchools[resolvedChapterId] ?? EditorMockData.schools
            case .school, .part:
                branchOptions = []
                schoolOptions = []
            }
        }
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

    func selectCategory(_ category: EditorMainCategory) {
        selectedCategory = category
        Task {
            await loadTargetOptions()
        }
    }

    func toggleSubCategory(_ subCategory: EditorSubCategory) {
        if subCategory == .all {
            if subCategorySelection.selectedSubCategories.contains(.all) {
                subCategorySelection.selectedSubCategories.remove(.all)
            } else {
                subCategorySelection.selectedSubCategories = [.all]
                subCategorySelection.selectedBranch = nil
                subCategorySelection.selectedSchool = nil
                subCategorySelection.selectedParts = []
            }
        } else {
            subCategorySelection.selectedSubCategories.remove(.all)

            if subCategorySelection.selectedSubCategories.contains(subCategory) {
                subCategorySelection.selectedSubCategories.remove(subCategory)
                clearFilterForSubCategory(subCategory)
            } else {
                subCategorySelection.selectedSubCategories.insert(subCategory)
            }

            if subCategorySelection.selectedSubCategories.isEmpty {
                subCategorySelection.selectedSubCategories = [.all]
            }
        }
    }

    func toggleBranch(_ branch: NoticeTargetOption) {
        if subCategorySelection.selectedBranch == branch {
            subCategorySelection.selectedBranch = nil
        } else {
            subCategorySelection.selectedBranch = branch
        }
    }

    func toggleSchool(_ school: NoticeTargetOption) {
        if subCategorySelection.selectedSchool == school {
            subCategorySelection.selectedSchool = nil
        } else {
            subCategorySelection.selectedSchool = school
        }
    }

    func togglePart(_ part: UMCPartType) {
        if subCategorySelection.selectedParts.contains(part) {
            subCategorySelection.selectedParts.remove(part)
        } else {
            subCategorySelection.selectedParts.insert(part)
        }
    }

    func isSubCategorySelected(_ subCategory: EditorSubCategory) -> Bool {
        subCategorySelection.selectedSubCategories.contains(subCategory)
    }

    /// 게시판 분류 칩의 시각적 선택 상태를 반환합니다.
    /// 필터형 칩(지부/학교/파트)은 실제 선택값이 있을 때만 선택으로 표시합니다.
    func isSubCategoryHighlighted(_ subCategory: EditorSubCategory) -> Bool {
        switch subCategory {
        case .all:
            return subCategorySelection.selectedSubCategories.contains(.all)
        case .branch:
            return subCategorySelection.selectedBranch != nil
        case .school:
            return subCategorySelection.selectedSchool != nil
        case .part:
            return !subCategorySelection.selectedParts.isEmpty
        }
    }

    func isBranchSelected(_ branch: NoticeTargetOption) -> Bool {
        subCategorySelection.selectedBranch == branch
    }

    func isSchoolSelected(_ school: NoticeTargetOption) -> Bool {
        subCategorySelection.selectedSchool == school
    }

    func isPartSelected(_ part: UMCPartType) -> Bool {
        subCategorySelection.selectedParts.contains(part)
    }

    /// 필터형 서브카테고리(지부/학교/파트)를 탭했을 때 선택 상태를 보장합니다.
    func selectSubCategoryIfNeeded(_ subCategory: EditorSubCategory) {
        guard subCategory.hasFilter else { return }

        if !subCategorySelection.selectedSubCategories.contains(subCategory) {
            subCategorySelection.selectedSubCategories.remove(.all)
            subCategorySelection.selectedSubCategories.insert(subCategory)
        }
    }

    func openSheet(for subCategory: EditorSubCategory) {
        // 시트를 열 때 최신 타겟 목록을 다시 조회합니다.
        Task { @MainActor in
            await loadTargetOptions()
        }

        switch subCategory {
        case .branch:
            activeSheetType = .branch
        case .school:
            activeSheetType = .school
        case .part:
            activeSheetType = .part
        default:
            break
        }
    }

    // MARK: - Vote Action

    func showVotingFormSheet() {
        if isVoteConfirmed {
            alertPrompt = AlertPrompt(
                id: .init(),
                title: "투표가 이미 생성되었습니다",
                message: "투표 카드를 눌러 수정하거나 삭제할 수 있습니다.",
                positiveBtnTitle: "확인"
            )
        } else {
            voteFormData = VoteFormData()
            originalVoteFormData = nil
            showVoting = true
        }
    }

    func cancelVotingEdit() {
        if isVoteConfirmed, let original = originalVoteFormData {
            voteFormData = original
        } else if !isVoteConfirmed {
            voteFormData = VoteFormData()
        }

        originalVoteFormData = nil
        showVoting = false
    }

    func confirmVote() {
        isVoteConfirmed = true
        originalVoteFormData = nil
        showVoting = false
    }

    func editVote() {
        originalVoteFormData = VoteFormData(
            title: voteFormData.title,
            options: voteFormData.options.map { VoteOptionItem(text: $0.text) },
            isAnonymous: voteFormData.isAnonymous,
            allowMultipleSelection: voteFormData.allowMultipleSelection,
            startDate: voteFormData.startDate,
            endDate: voteFormData.endDate
        )
        showVoting = true
    }

    func deleteVote() {
        voteFormData = VoteFormData()
        isVoteConfirmed = false
        originalVoteFormData = nil
    }

    func addVoteOption() {
        guard voteFormData.canAddOption else { return }
        voteFormData.options.append(VoteOptionItem())
    }

    func removeVoteOption(_ option: VoteOptionItem) {
        guard voteFormData.canRemoveOption else { return }
        voteFormData.options.removeAll { $0.id == option.id }
    }

    // MARK: - Image Action

    /// 선택한 이미지를 로컬 카드 목록으로 반영합니다.
    ///
    /// 실제 서버 업로드는 저장 시점(`saveNotice`)에서만 수행됩니다.
    @MainActor
    func didLoadImages(images: [UIImage]) async {
        for image in images {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { continue }
            noticeImages.append(
                NoticeImageItem(
                    imageData: imageData,
                    isLoading: false,
                    fileId: nil
                )
            )
        }

        selectedPhotoItems.removeAll()
    }

    func removeImage(_ item: NoticeImageItem) {
        noticeImages.removeAll { $0.id == item.id }
    }

    // MARK: - Link Action

    func removeLink(_ link: NoticeLinkItem) {
        noticeLinks.removeAll { $0.id == link.id }
    }

    // MARK: - Private

    /// 수정할 공지 데이터를 에디터 상태로 로드합니다.
    private func loadNoticeForEdit(_ notice: NoticeDetail) {
        title = notice.title
        content = notice.content
        originalTitle = notice.title
        originalContent = notice.content

        noticeLinks = notice.links.map { NoticeLinkItem(link: $0) }
        originalLinks = notice.links

        // 기존 서버 이미지의 교체/삭제 API 명세가 정리되기 전까지,
        // 수정 화면에서는 신규 추가 이미지 중심으로 동작합니다.
        noticeImages = []

        if let vote = notice.vote {
            voteFormData = VoteFormData(
                title: vote.question,
                options: vote.options.map { VoteOptionItem(text: $0.title) },
                isAnonymous: vote.isAnonymous,
                allowMultipleSelection: vote.allowMultipleChoices,
                startDate: vote.startDate,
                endDate: vote.endDate
            )
            isVoteConfirmed = true
        }
    }

    private static func availableCategories(for organizationType: OrganizationType?) -> [EditorMainCategory] {
        switch organizationType {
        case .central:
            return [.central, .branch, .school]
        case .chapter, .school, .none:
            return [.branch, .school]
        }
    }

    @MainActor
    private func createNewNotice() async {
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

    @MainActor
    private func updateExistingNotice(noticeId: Int) async {
        createState = .loading

        do {
            let imageIds = try await uploadPendingImagesIfNeeded()

            var updatedNotice = try await noticeUseCase.updateNotice(
                noticeId: noticeId,
                title: title,
                content: content
            )

            let links = sanitizedLinksForRequest()
            updatedNotice = try await noticeUseCase.updateLinks(
                noticeId: noticeId,
                links: links
            )

            if !imageIds.isEmpty {
                updatedNotice = try await noticeUseCase.updateImages(
                    noticeId: noticeId,
                    imageIds: imageIds
                )
            }

            createState = .loaded(updatedNotice)
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

    @MainActor
    private func createVote(noticeId: Int) async throws -> AddVoteResponseDTO {
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
    ///
    /// - Note: 서버 스펙 기준으로 `targetInfo`는 단일 객체입니다.
    private func buildTargetInfo() -> TargetInfoDTO {
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

    private func resetForm() {
        title = ""
        content = ""
        noticeImages = []
        noticeLinks = []
        voteFormData = VoteFormData()
        isVoteConfirmed = false
        allowAlert = true
    }

    private func clearFilterForSubCategory(_ subCategory: EditorSubCategory) {
        switch subCategory {
        case .branch:
            subCategorySelection.selectedBranch = nil
        case .school:
            subCategorySelection.selectedSchool = nil
        case .part:
            subCategorySelection.selectedParts = []
        default:
            break
        }
    }
    
    /// 링크 첨부 카드에서 입력된 값 중 실제 전송 가능한 링크만 추출합니다.
    ///
    /// - Note: 공백/빈 문자열은 제외합니다.
    private func sanitizedLinksForRequest() -> [String] {
        noticeLinks
            .map { $0.link.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    /// 투표 요청 전송 여부를 판단합니다.
    ///
    /// - Note: 투표 시트에서 확정되었고, 제목/옵션이 유효할 때만 전송합니다.
    private var shouldSendVoteRequest: Bool {
        guard isVoteConfirmed else { return false }
        
        let title = voteFormData.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !title.isEmpty && sanitizedVoteOptions().count >= 2
    }
    
    /// 투표 옵션 입력값 중 실제 전송 가능한 옵션만 추출합니다.
    private func sanitizedVoteOptions() -> [String] {
        voteFormData.options
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    /// 저장 실패를 전역 ErrorHandler로 전달합니다.
    private func handleError(_ error: Error, action: String) {
        guard let errorHandler else { return }
        errorHandler.handle(
            error,
            context: ErrorContext(feature: "Notice", action: action)
        )
    }

    /// 저장 시점에만 파일 업로드 플로우를 실행하고 fileId 배열을 반환합니다.
    @MainActor
    private func uploadPendingImagesIfNeeded() async throws -> [String] {
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
