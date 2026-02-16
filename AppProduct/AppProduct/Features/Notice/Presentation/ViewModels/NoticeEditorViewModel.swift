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
/// 공지 생성/수정, 카테고리 선택, 투표/링크/이미지 첨부를 관리합니다.
@Observable
final class NoticeEditorViewModel: MultiplePhotoPickerManageable {
    
    // MARK: - Property
    
    /// UseCase
    private let noticeUseCase: NoticeUseCaseProtocol
    private let storageUseCase: NoticeStorageUseCaseProtocol
    private let targetDataSource: NoticeEditorTargetDataSource
    
    /// 편집 모드 (생성 or 수정)
    private let mode: NoticeEditorMode
    
    /// UserDefaults 접근 - 사용자 정보 (computed properties)
    private var gisuId: Int {
        UserDefaults.standard.integer(forKey: AppStorageKey.gisuId)
    }

    private var organizationId: Int {
        UserDefaults.standard.integer(forKey: AppStorageKey.organizationId)
    }

    private var schoolId: Int {
        UserDefaults.standard.integer(forKey: AppStorageKey.schoolId)
    }

    /// 공지 생성 상태
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
    var activeSheetType: TargetSheetType? = nil
    
    /// 사용 가능한 카테고리 목록
    var availableCategories: [EditorMainCategory]
    
    /// 지부 선택 시트 목록 (중앙 선택 시만 사용)
    var branchOptions: [String] = []

    /// 학교 선택 시트 목록 (중앙: 전체 학교, 지부: 해당 지부 학교)
    var schoolOptions: [String] = []
    
    /// 공지사항 제목
    var title: String = ""
    
    /// 공지사항 본문
    var content: String = ""
    
    /// 투표 폼 시트뷰 표시 여부
    var showVoting: Bool = false
    
    /// 투표 폼 데이터
    var voteFormData: VoteFormData = VoteFormData()
    
    /// 수정 전 데이터
    private var originalVoteFormData: VoteFormData?
    
    /// 투표 확정 여부
    var isVoteConfirmed: Bool = false
    
    /// AlertPrompt
    var alertPrompt: AlertPrompt?
    
    /// PhotosPicker 선택 아이템
    var selectedPhotoItems: [PhotosPickerItem] = []
    
    /// 선택된 이미지
    var selectedImages: [UIImage] = []
    
    /// 첨부된 이미지 목록
    var noticeImages: [NoticeImageItem] = []
    
    /// 첨부된 링크 목록
    var noticeLinks: [NoticeLinkItem] = []
    
    /// 알림 발송 여부
    var allowAlert: Bool = true
    
    /// 작성 완료 가능 여부
    var canSubmit: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedTitle.isEmpty && !trimmedContent.isEmpty
    }
    
    /// 수정 모드 여부
    var isEditMode: Bool {
        if case .edit = mode {
            return true
        }
        return false
    }
    
    // MARK: - Initializer

    init(
        noticeUseCase: NoticeUseCaseProtocol,
        storageUseCase: NoticeStorageUseCaseProtocol,
        userPart: UMCPartType?,
        mode: NoticeEditorMode = .create,
        targetDataSource: NoticeEditorTargetDataSource = NoticeEditorMockTargetDataSource()
    ) {
        self.noticeUseCase = noticeUseCase
        self.storageUseCase = storageUseCase
        self.targetDataSource = targetDataSource
        self.mode = mode
        _ = userPart

        let categories: [EditorMainCategory] = [.branch, .school]

        self.availableCategories = categories
        self.selectedCategory = categories.first ?? .branch

        if case .edit(_, let notice) = mode {
            loadNoticeForEdit(notice)
        }
    }
    
    
    // MARK: - Function
    
    /// 수정할 공지 데이터 로드 (제목, 본문, 링크, 이미지만)
    private func loadNoticeForEdit(_ notice: NoticeDetail) {
        title = notice.title
        content = notice.content

        // 링크 로드
        noticeLinks = notice.links.map { NoticeLinkItem(link: $0) }

        // 이미지 로드 (서버 이미지 → NoticeImageItem)
        // TODO: 서버 이미지 URL을 Data로 변환하는 로직 필요
        // 현재는 빈 배열로 설정 (이미지 수정 시 새로 추가하는 방식)
        noticeImages = []

        // 투표 정보 읽기 전용으로 표시 (수정 불가)
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

    /// 현재 메인 카테고리에 맞는 타겟 목록을 조회합니다.
    ///
    /// - 중앙: 지부 전체 + 학교 전체
    /// - 지부: 학교(본인 지부 소속)만
    /// - 학교: 별도 조회 없음
    @MainActor
    func loadTargetOptions() async {
        do {
            switch selectedCategory {
            case .central:
                async let branches = targetDataSource.fetchAllBranches()
                async let schools = targetDataSource.fetchAllSchools()
                branchOptions = try await branches
                schoolOptions = try await schools
            case .branch:
                branchOptions = []
                schoolOptions = try await targetDataSource.fetchSchools(inChapterId: organizationId)
            case .school, .part:
                branchOptions = []
                schoolOptions = []
            }
        } catch {
            // 조회 실패 시 선택 시트가 비어 보이지 않도록 기본 Mock 값으로 폴백
            switch selectedCategory {
            case .central:
                branchOptions = EditorMockData.branches
                schoolOptions = EditorMockData.schools
            case .branch:
                branchOptions = []
                schoolOptions = EditorMockData.chapterSchools[organizationId] ?? EditorMockData.schools
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

    /// 새 공지 생성
    @MainActor
    private func createNewNotice() async {
        createState = .loading

        do {
            // 1. targetInfo 구성
            let targetInfo = buildTargetInfo()

            // 2. links 추출
            let links = noticeLinks.map { $0.link }

            // 3. imageIds 추출 (업로드 완료된 이미지의 fileId)
            let imageIds: [String] = noticeImages.compactMap { $0.fileId }

            // 4. UseCase 호출
            let notice = try await noticeUseCase.createNotice(
                title: title,
                content: content,
                shouldNotify: allowAlert,
                targetInfo: targetInfo,
                links: links,
                imageIds: imageIds
            )

            // 5. 투표가 확정되었으면 투표 추가
            if isVoteConfirmed, let noticeId = Int(notice.id) {
                _ = try await createVote(noticeId: noticeId)
            }

            createState = .loaded(notice)

            // 성공 시 초기화
            resetForm()

        } catch let error as DomainError {
            createState = .failed(.domain(error))
        } catch let error as NetworkError {
            createState = .failed(.network(error))
        } catch {
            createState = .failed(.unknown(message: error.localizedDescription))
        }
    }

    /// 기존 공지 수정 (제목, 본문, 링크, 이미지만)
    @MainActor
    private func updateExistingNotice(noticeId: Int) async {
        createState = .loading

        do {
            // 1. 제목/본문 수정
            var updatedNotice = try await noticeUseCase.updateNotice(
                noticeId: noticeId,
                title: title,
                content: content
            )

            // 2. 링크 수정
            let links = noticeLinks.map { $0.link }
            updatedNotice = try await noticeUseCase.updateLinks(
                noticeId: noticeId,
                links: links
            )

            // 3. 이미지 수정 (업로드 완료된 이미지의 fileId)
            let imageIds: [String] = noticeImages.compactMap { $0.fileId }
            if !imageIds.isEmpty {
                updatedNotice = try await noticeUseCase.updateImages(
                    noticeId: noticeId,
                    imageIds: imageIds
                )
            }

            createState = .loaded(updatedNotice)

            // 성공 알림
            alertPrompt = AlertPrompt(
                id: .init(),
                title: "수정 완료",
                message: "공지사항이 수정되었습니다.",
                positiveBtnTitle: "확인"
            )

        } catch let error as DomainError {
            createState = .failed(.domain(error))
        } catch let error as NetworkError {
            createState = .failed(.network(error))
        } catch {
            createState = .failed(.unknown(message: error.localizedDescription))
        }
    }
    
    /// 투표 생성
    @MainActor
    private func createVote(noticeId: Int) async throws -> AddVoteResponseDTO {
        // VoteFormData → API 파라미터 변환이
        let options = voteFormData.options
            .map { $0.text.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }  // 빈 옵션 제거

        return try await noticeUseCase.addVote(
            noticeId: noticeId,
            title: voteFormData.title,
            isAnonymous: voteFormData.isAnonymous,
            allowMultipleChoice: voteFormData.allowMultipleSelection,
            startsAt: voteFormData.startDate,
            endsAtExclusive: voteFormData.endDate,
            options: options
        )
    }
    
    // MARK: - Private Helpers
    
    /// TargetInfoDTO 배열 생성
    private func buildTargetInfo() -> [TargetInfoDTO] {
        let currentGeneration = gisuId
        
        var targetInfoList: [TargetInfoDTO] = []
        
        switch selectedCategory {
        case .central:
            // 중앙: 파트별 또는 전체
            if subCategorySelection.selectedSubCategories.contains(.all) {
                // 전체
                targetInfoList.append(TargetInfoDTO(
                    targetGisuId: currentGeneration,
                    targetChapterId: nil,
                    targetSchoolId: nil,
                    targetParts: nil
                ))
            } else {
                // 파트별
                for part in subCategorySelection.selectedParts {
                    targetInfoList.append(TargetInfoDTO(
                        targetGisuId: currentGeneration,
                        targetChapterId: nil,
                        targetSchoolId: nil,
                        targetParts: part
                    ))
                }
            }
            
        case .branch:
            // 지부별
            if subCategorySelection.selectedSubCategories.contains(.all) {
                // 전체 지부
                targetInfoList.append(TargetInfoDTO(
                    targetGisuId: currentGeneration,
                    targetChapterId: organizationId, // AppStorage 사용
                    targetSchoolId: nil,
                    targetParts: nil
                ))
            } else {
                // 특정 지부들 (선택된 지부 목록 사용)
                // Note: 여러 지부 선택 시 각각 TargetInfoDTO 생성
                for _ in subCategorySelection.selectedBranches {
                    targetInfoList.append(TargetInfoDTO(
                        targetGisuId: currentGeneration,
                        targetChapterId: organizationId, // AppStorage 사용
                        targetSchoolId: nil,
                        targetParts: nil
                    ))
                }
            }
            
        case .school:
            // 학교별
            if subCategorySelection.selectedSubCategories.contains(.all) {
                // 전체 학교
                targetInfoList.append(TargetInfoDTO(
                    targetGisuId: currentGeneration,
                    targetChapterId: nil,
                    targetSchoolId: schoolId, // AppStorage 사용
                    targetParts: nil
                ))
            } else {
                // 특정 학교들
                for _ in subCategorySelection.selectedSchools {
                    targetInfoList.append(TargetInfoDTO(
                        targetGisuId: currentGeneration,
                        targetChapterId: nil,
                        targetSchoolId: schoolId, // AppStorage 사용
                        targetParts: nil
                    ))
                }
            }
            
        case .part(let part):
            // 파트 공지
            targetInfoList.append(TargetInfoDTO(
                targetGisuId: currentGeneration,
                targetChapterId: nil,
                targetSchoolId: nil,
                targetParts: part
            ))
        }
        
        return targetInfoList
    }
    
    /// 폼 초기화
    private func resetForm() {
        title = ""
        content = ""
        noticeImages = []
        noticeLinks = []
        voteFormData = VoteFormData()
        isVoteConfirmed = false
        allowAlert = true
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
                subCategorySelection.selectedBranches = []
                subCategorySelection.selectedSchools = []
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
    
    func toggleBranch(_ branch: String) {
        if subCategorySelection.selectedBranches.contains(branch) {
            subCategorySelection.selectedBranches.remove(branch)
        } else {
            subCategorySelection.selectedBranches.insert(branch)
        }
    }
    
    func toggleSchool(_ school: String) {
        if subCategorySelection.selectedSchools.contains(school) {
            subCategorySelection.selectedSchools.remove(school)
        } else {
            subCategorySelection.selectedSchools.insert(school)
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
            return !subCategorySelection.selectedBranches.isEmpty
        case .school:
            return !subCategorySelection.selectedSchools.isEmpty
        case .part:
            return !subCategorySelection.selectedParts.isEmpty
        }
    }
    
    func isBranchSelected(_ branch: String) -> Bool {
        subCategorySelection.selectedBranches.contains(branch)
    }
    
    func isSchoolSelected(_ school: String) -> Bool {
        subCategorySelection.selectedSchools.contains(school)
    }
    
    func isPartSelected(_ part: UMCPartType) -> Bool {
        subCategorySelection.selectedParts.contains(part)
    }

    /// 필터형 서브카테고리(지부/학교/파트)를 탭했을 때
    /// 선택 상태를 보장합니다. (이미 선택되어 있으면 유지)
    func selectSubCategoryIfNeeded(_ subCategory: EditorSubCategory) {
        guard subCategory.hasFilter else { return }

        if !subCategorySelection.selectedSubCategories.contains(subCategory) {
            subCategorySelection.selectedSubCategories.remove(.all)
            subCategorySelection.selectedSubCategories.insert(subCategory)
        }
    }
    
    func openSheet(for subCategory: EditorSubCategory) {
        switch subCategory {
        case .branch: activeSheetType = .branch
        case .school: activeSheetType = .school
        case .part: activeSheetType = .part
        default: break
        }
    }
    
    
    // MARK: - Vote Function
    
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
    
    // MARK: - Image Function
    
    @MainActor
    func didLoadImages(images: [UIImage]) async {
        // 각 이미지에 대한 로딩 placeholder 생성
        var loadingItemIds: [UUID] = []

        for _ in images {
            let item = NoticeImageItem(imageData: nil, isLoading: true, fileId: nil)
            loadingItemIds.append(item.id)
            noticeImages.append(item)
        }

        // 이미지 업로드 및 fileId 저장
        for (index, image) in images.enumerated() {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { continue }

            let loadingId = loadingItemIds[index]

            do {
                // ✅ Storage API로 이미지 업로드
                let fileId = try await storageUseCase.uploadImage(image, category: .noticeAttachment)

                // ✅ fileId와 함께 이미지 저장
                if let loadingIndex = noticeImages.firstIndex(where: { $0.id == loadingId }) {
                    noticeImages[loadingIndex] = NoticeImageItem(
                        imageData: imageData,
                        isLoading: false,
                        fileId: fileId
                    )
                }
            } catch {
                // 업로드 실패 시 해당 아이템 제거
                noticeImages.removeAll { $0.id == loadingId }

                // 에러 알림
                alertPrompt = AlertPrompt(
                    id: .init(),
                    title: "이미지 업로드 실패",
                    message: "이미지를 업로드하는 중 오류가 발생했습니다.",
                    positiveBtnTitle: "확인"
                )
            }
        }

        selectedPhotoItems.removeAll()
    }
    
    func removeImage(_ item: NoticeImageItem) {
        noticeImages.removeAll { $0.id == item.id }
    }
    
    // MARK: - Link Function
    
    func removeLink(_ link: NoticeLinkItem) {
        noticeLinks.removeAll { $0.id == link.id }
    }
    
    
    // MARK: - Private
    
    private func clearFilterForSubCategory(_ subCategory: EditorSubCategory) {
        switch subCategory {
        case .branch:
            subCategorySelection.selectedBranches = []
        case .school:
            subCategorySelection.selectedSchools = []
        case .part:
            subCategorySelection.selectedParts = []
        default:
            break
        }
    }
}
