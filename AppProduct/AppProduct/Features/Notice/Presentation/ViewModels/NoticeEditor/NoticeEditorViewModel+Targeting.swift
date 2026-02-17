//
//  NoticeEditorViewModel+Targeting.swift
//  AppProduct
//
//  Created by euijjang97 on 2/17/26.
//

import Foundation

extension NoticeEditorViewModel {

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

    /// 메인 카테고리를 선택하고 해당 타겟 옵션을 로드합니다.
    func selectCategory(_ category: EditorMainCategory) {
        selectedCategory = category
        Task {
            await loadTargetOptions()
        }
    }

    /// 서브카테고리 토글 (전체 선택 시 개별 필터 초기화, 개별 해제 시 전체로 복원)
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

    /// 지부 선택 토글
    func toggleBranch(_ branch: NoticeTargetOption) {
        if subCategorySelection.selectedBranch == branch {
            subCategorySelection.selectedBranch = nil
        } else {
            subCategorySelection.selectedBranch = branch
        }
    }

    /// 학교 선택 토글
    func toggleSchool(_ school: NoticeTargetOption) {
        if subCategorySelection.selectedSchool == school {
            subCategorySelection.selectedSchool = nil
        } else {
            subCategorySelection.selectedSchool = school
        }
    }

    /// 파트 선택 토글
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

    /// 서브카테고리에 맞는 타겟 선택 시트를 엽니다.
    func openSheet(for subCategory: EditorSubCategory) {
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

    // MARK: - Edit Bootstrap

    /// 수정할 공지 데이터를 에디터 상태로 로드합니다.
    func loadNoticeForEdit(_ notice: NoticeDetail) {
        title = notice.title
        content = notice.content
        originalTitle = notice.title
        originalContent = notice.content

        noticeLinks = notice.links.map { NoticeLinkItem(link: $0) }
        originalLinks = notice.links
        let imagesFromMeta = notice.imageItems
            .filter { !$0.id.isEmpty }
            .map {
                NoticeImageItem(
                    imageData: nil,
                    imageURL: $0.url,
                    isLoading: false,
                    fileId: $0.id
                )
            }
        let imagesFromURLs = notice.images.map {
            NoticeImageItem(
                imageData: nil,
                imageURL: $0,
                isLoading: false,
                fileId: nil
            )
        }

        noticeImages = imagesFromMeta.isEmpty ? imagesFromURLs : imagesFromMeta
        originalImageIds = imagesFromMeta.compactMap(\.fileId)
        originalImageURLs = notice.images

        if let vote = notice.vote {
            let loadedVoteForm = VoteFormData(
                title: vote.question,
                options: vote.options.map { VoteOptionItem(text: $0.title) },
                isAnonymous: vote.isAnonymous,
                allowMultipleSelection: vote.allowMultipleChoices,
                startDate: vote.startDate,
                endDate: vote.endDate
            )
            voteFormData = loadedVoteForm
            isVoteConfirmed = true
            initialVoteSnapshot = makeVoteSnapshot(from: loadedVoteForm)
        } else {
            initialVoteSnapshot = nil
            isVoteConfirmed = false
        }
    }

    // MARK: - Helper

    /// 조직 타입에 따라 사용 가능한 메인 카테고리 목록을 반환합니다.
    static func availableCategories(for organizationType: OrganizationType?) -> [EditorMainCategory] {
        switch organizationType {
        case .central:
            return [.central, .branch, .school]
        case .chapter, .school, .none:
            return [.branch, .school]
        }
    }

    /// 해당 서브카테고리의 필터 선택 상태를 초기화합니다.
    func clearFilterForSubCategory(_ subCategory: EditorSubCategory) {
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
}
