//
//  NoticeEditorViewModel+Targeting.swift
//  AppProduct
//
//  Created by euijjang97 on 2/17/26.
//

import Foundation

extension NoticeEditorViewModel {

    // MARK: - Public State

    /// 현재 권한 기준으로 노출 가능한 서브카테고리 목록입니다.
    var visibleSubCategories: [EditorSubCategory] {
        Self.allowedSubCategories(
            for: selectedCategory,
            memberRole: memberRole
        )
    }

    /// 공지 생성 시 현재 타겟 조합의 유효성입니다.
    var isTargetSelectionValid: Bool {
        targetValidationMessage == nil
    }

    /// 공지 생성 시 타겟 조합 검증 메시지입니다.
    var targetValidationMessage: String? {
        guard !isEditMode else { return nil }

        if memberRole == .superAdmin {
            return "시스템 관리자는 공지 작성 권한이 없습니다."
        }

        let hasGisu = resolvedGisuId > 0
        let hasBranch = subCategorySelection.selectedBranch != nil
        let hasSchool = subCategorySelection.selectedSchool != nil
        let hasParts = !subCategorySelection.selectedParts.isEmpty
        let canPickBranch = visibleSubCategories.contains(.branch)
        let canPickSchool = visibleSubCategories.contains(.school)

        // 지부/학교는 단일 선택이며, 노출되는 경우 최소 1개는 반드시 선택해야 합니다.
        if canPickBranch && canPickSchool {
            if !hasBranch && !hasSchool {
                return "지부 또는 학교를 하나 선택해주세요."
            }
        } else if canPickBranch && !hasBranch {
            return "지부를 선택해주세요."
        } else if canPickSchool && !hasSchool {
            return "학교를 선택해주세요."
        }

        if selectedCategory == .all {
            if hasBranch || hasParts {
                return "전체 기수 대상에서는 지부/파트를 함께 지정할 수 없습니다."
            }
            return nil
        }

        if hasBranch && hasSchool {
            return "지부와 학교는 동시에 선택할 수 없습니다."
        }

        if !hasGisu {
            if selectedCategory == .branch || hasBranch {
                return "기수를 선택하지 않은 경우 지부 대상 공지는 작성할 수 없습니다."
            }
            if hasSchool && hasParts {
                return "기수를 선택하지 않은 경우 학교와 파트를 동시에 지정할 수 없습니다."
            }
        }

        return nil
    }

    // MARK: - Public Action

    /// 조직 타입 기준으로 메인 카테고리 목록을 갱신합니다.
    func applyOrganizationType(_ organizationTypeRawValue: String) {
        organizationType = OrganizationType(rawValue: organizationTypeRawValue)
        // 메뉴/권한 정책은 memberRole 기준으로만 관리합니다.
    }

    /// 멤버 역할 기준으로 메인 카테고리/서브카테고리 정책을 갱신합니다.
    func applyMemberRole(_ memberRoleRawValue: String) {
        memberRole = ManagementTeam(rawValue: memberRoleRawValue)
        applyEditorPolicyAndReloadTargets()
    }

    /// 뷰에서 사용자 컨텍스트(AppStorage)를 전달받아 반영합니다.
    func updateUserContext(gisuId: Int, chapterId: Int) {
        userGisuId = gisuId
        userChapterId = chapterId

        normalizeSelectionForCurrentCategory()
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
            case .all:
                branchOptions = []
                schoolOptions = []
            case .central:
                let canSelectBranch = visibleSubCategories.contains(.branch)
                let canSelectSchool = visibleSubCategories.contains(.school)

                if canSelectBranch, canSelectSchool {
                    async let branches = targetUseCase.fetchAllBranches()
                    async let schools = targetUseCase.fetchAllSchools()
                    branchOptions = try await branches
                    schoolOptions = try await schools
                } else if canSelectBranch {
                    branchOptions = try await targetUseCase.fetchAllBranches()
                    schoolOptions = []
                } else if canSelectSchool {
                    branchOptions = []
                    schoolOptions = try await targetUseCase.fetchAllSchools()
                } else {
                    branchOptions = []
                    schoolOptions = []
                }
            case .branch:
                if visibleSubCategories.contains(.branch) {
                    branchOptions = try await targetUseCase.fetchAllBranches()
                } else {
                    branchOptions = []
                }
                if visibleSubCategories.contains(.school) {
                    schoolOptions = try await targetUseCase.fetchSchools(
                        inChapterId: resolvedChapterId,
                        gisuId: resolvedGisuId
                    )
                } else {
                    schoolOptions = []
                }
            case .school:
                branchOptions = []
                if visibleSubCategories.contains(.school) {
                    schoolOptions = try await targetUseCase.fetchAllSchools()
                } else {
                    schoolOptions = []
                }
            case .part:
                branchOptions = []
                schoolOptions = []
            }
        } catch {
            switch selectedCategory {
            case .all:
                branchOptions = []
                schoolOptions = []
            case .central:
                branchOptions = visibleSubCategories.contains(.branch) ? EditorMockData.branches : []
                schoolOptions = visibleSubCategories.contains(.school) ? EditorMockData.schools : []
            case .branch:
                branchOptions = visibleSubCategories.contains(.branch) ? EditorMockData.branches : []
                schoolOptions = visibleSubCategories.contains(.school)
                    ? (EditorMockData.chapterSchools[resolvedChapterId] ?? EditorMockData.schools)
                    : []
            case .school:
                branchOptions = []
                schoolOptions = visibleSubCategories.contains(.school) ? EditorMockData.schools : []
            case .part:
                branchOptions = []
                schoolOptions = []
            }
        }

        normalizeSelectionForCurrentCategory()
    }

    /// 메인 카테고리를 선택하고 해당 타겟 옵션을 로드합니다.
    func selectCategory(_ category: EditorMainCategory) {
        guard availableCategories.contains(category) else { return }
        selectedCategory = category
        normalizeSelectionForCurrentCategory()
        Task { @MainActor in
            await loadTargetOptions()
        }
    }

    /// 서브카테고리 토글 (전체 선택 시 개별 필터 초기화, 개별 해제 시 전체로 복원)
    func toggleSubCategory(_ subCategory: EditorSubCategory) {
        guard visibleSubCategories.contains(subCategory) else { return }

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

        normalizeSelectionForCurrentCategory()
    }

    /// 지부 선택 토글
    func toggleBranch(_ branch: NoticeTargetOption) {
        guard visibleSubCategories.contains(.branch) else { return }

        if subCategorySelection.selectedBranch == branch {
            subCategorySelection.selectedBranch = nil
            subCategorySelection.selectedSubCategories.remove(.branch)
        } else {
            subCategorySelection.selectedBranch = branch
            subCategorySelection.selectedSchool = nil
            subCategorySelection.selectedSubCategories.remove(.all)
            subCategorySelection.selectedSubCategories.remove(.school)
            subCategorySelection.selectedSubCategories.insert(.branch)
        }

        if subCategorySelection.selectedSubCategories.isEmpty {
            subCategorySelection.selectedSubCategories = [.all]
        }

        normalizeSelectionForCurrentCategory()
    }

    /// 학교 선택 토글
    func toggleSchool(_ school: NoticeTargetOption) {
        guard visibleSubCategories.contains(.school) else { return }

        if subCategorySelection.selectedSchool == school {
            subCategorySelection.selectedSchool = nil
            subCategorySelection.selectedSubCategories.remove(.school)
        } else {
            subCategorySelection.selectedSchool = school
            subCategorySelection.selectedBranch = nil
            subCategorySelection.selectedSubCategories.remove(.all)
            subCategorySelection.selectedSubCategories.remove(.branch)
            subCategorySelection.selectedSubCategories.insert(.school)
        }

        if subCategorySelection.selectedSubCategories.isEmpty {
            subCategorySelection.selectedSubCategories = [.all]
        }

        normalizeSelectionForCurrentCategory()
    }

    /// 파트 선택 토글
    func togglePart(_ part: UMCPartType) {
        guard visibleSubCategories.contains(.part) else { return }

        if subCategorySelection.selectedParts.contains(part) {
            subCategorySelection.selectedParts.remove(part)
        } else {
            subCategorySelection.selectedParts.insert(part)
        }

        subCategorySelection.selectedSubCategories.remove(.all)
        if subCategorySelection.selectedParts.isEmpty {
            subCategorySelection.selectedSubCategories.remove(.part)
        } else {
            subCategorySelection.selectedSubCategories.insert(.part)
        }

        if subCategorySelection.selectedSubCategories.isEmpty {
            subCategorySelection.selectedSubCategories = [.all]
        }

        normalizeSelectionForCurrentCategory()
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
        guard visibleSubCategories.contains(subCategory) else { return }

        if !subCategorySelection.selectedSubCategories.contains(subCategory) {
            subCategorySelection.selectedSubCategories.remove(.all)
            subCategorySelection.selectedSubCategories.insert(subCategory)
        }
        normalizeSelectionForCurrentCategory()
    }

    /// 서브카테고리에 맞는 타겟 선택 시트를 엽니다.
    func openSheet(for subCategory: EditorSubCategory) {
        guard subCategory.hasFilter else { return }
        guard visibleSubCategories.contains(subCategory) else { return }

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
                    uploadFileName: nil,
                    isLoading: false,
                    fileId: $0.id
                )
            }
        let imagesFromURLs = notice.images.map {
            NoticeImageItem(
                imageData: nil,
                imageURL: $0,
                uploadFileName: nil,
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

    /// 조직 타입/역할에 따라 사용 가능한 메인 카테고리 목록을 반환합니다.
    static func availableCategories(
        for _: OrganizationType?,
        memberRole: ManagementTeam?
    ) -> [EditorMainCategory] {
        switch roleGroup(from: memberRole) {
        case .central:
            // CENTRAL 계열: 상단 메뉴에서 "중앙" 제거
            return [.all, .branch, .school]
        case .school:
            // SCHOOL: 상단 메뉴는 전체기수/학교
            return [.all, .school]
        case .chapter:
            // CHAPTER: 상단 메뉴는 지부만
            return [.branch]
        case .noPermission:
            return [.all]
        case .unknown:
            return [.all, .branch, .school]
        }
    }

    /// 레거시 시그니처 유지용 래퍼입니다.
    static func availableCategories(for organizationType: OrganizationType?) -> [EditorMainCategory] {
        availableCategories(for: organizationType, memberRole: nil)
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

// MARK: - Private Policy
private extension NoticeEditorViewModel {

    enum RoleGroup {
        case central
        case chapter
        case school
        case noPermission
        case unknown
    }

    static func roleGroup(from memberRole: ManagementTeam?) -> RoleGroup {
        switch memberRole {
        case .centralPresident, .centralVicePresident, .centralOperatingTeamMember, .centralEducationTeamMember:
            return .central
        case .chapterPresident:
            return .chapter
        case .schoolPresident, .schoolVicePresident, .schoolPartLeader, .schoolEtcAdmin:
            return .school
        case .superAdmin:
            return .noPermission
        case .challenger:
            return .unknown
        case .none:
            return .unknown
        }
    }

    static func allowedSubCategories(
        for category: EditorMainCategory,
        memberRole: ManagementTeam?
    ) -> [EditorSubCategory] {
        switch roleGroup(from: memberRole) {
        case .central:
            // CENTRAL: 하단 칩은 전체/파트
            return [.all, .part]
        case .school:
            // SCHOOL: 하단 칩은 학교/파트
            return [.school, .part]
        case .chapter:
            // CHAPTER: 하단 칩은 지부/학교
            return [.branch, .school]
        case .noPermission:
            return []
        case .unknown:
            return category.subCategories
        }
    }

    func applyEditorPolicyAndReloadTargets() {
        let categories = Self.availableCategories(
            for: organizationType,
            memberRole: memberRole
        )

        if categories != availableCategories {
            availableCategories = categories
        }

        if !availableCategories.contains(selectedCategory) {
            selectedCategory = availableCategories.first ?? .branch
        }

        normalizeSelectionForCurrentCategory()

        Task { @MainActor in
            await loadTargetOptions()
        }
    }

    func normalizeSelectionForCurrentCategory() {
        let allowed = Set(visibleSubCategories)
        subCategorySelection.selectedSubCategories = subCategorySelection
            .selectedSubCategories
            .filter { allowed.contains($0) }

        if !allowed.contains(.branch) {
            subCategorySelection.selectedBranch = nil
        }
        if !allowed.contains(.school) {
            subCategorySelection.selectedSchool = nil
        }
        if !allowed.contains(.part) {
            subCategorySelection.selectedParts = []
        }

        // 지부/학교 동시 지정 방지
        if subCategorySelection.selectedBranch != nil && subCategorySelection.selectedSchool != nil {
            subCategorySelection.selectedSchool = nil
            subCategorySelection.selectedSubCategories.remove(.school)
        }

        // 전체 선택과 개별 필터는 동시 유지하지 않음
        if allowed.isEmpty {
            subCategorySelection.selectedSubCategories = []
            subCategorySelection.selectedBranch = nil
            subCategorySelection.selectedSchool = nil
            subCategorySelection.selectedParts = []
        } else if subCategorySelection.selectedSubCategories.contains(.all) {
            subCategorySelection.selectedSubCategories = [.all]
            subCategorySelection.selectedBranch = nil
            subCategorySelection.selectedSchool = nil
            subCategorySelection.selectedParts = []
        } else if subCategorySelection.selectedSubCategories.isEmpty {
            if allowed.contains(.all) {
                subCategorySelection.selectedSubCategories = [.all]
            } else if let firstAllowed = allowed.first {
                subCategorySelection.selectedSubCategories = [firstAllowed]
            }
        }

        // 기수 미선택 시 금지 조합 방지
        if resolvedGisuId <= 0 && subCategorySelection.selectedSchool != nil && !subCategorySelection.selectedParts.isEmpty {
            subCategorySelection.selectedParts = []
            subCategorySelection.selectedSubCategories.remove(.part)
            if subCategorySelection.selectedSubCategories.isEmpty {
                subCategorySelection.selectedSubCategories = [.all]
            }
        }

        // 옵션 목록에서 제거된 항목 정리
        if let selectedBranch = subCategorySelection.selectedBranch,
           !branchOptions.contains(selectedBranch) {
            subCategorySelection.selectedBranch = nil
            subCategorySelection.selectedSubCategories.remove(.branch)
        }

        if let selectedSchool = subCategorySelection.selectedSchool,
           !schoolOptions.contains(selectedSchool) {
            subCategorySelection.selectedSchool = nil
            subCategorySelection.selectedSubCategories.remove(.school)
        }

        if !allowed.isEmpty && subCategorySelection.selectedSubCategories.isEmpty {
            if allowed.contains(.all) {
                subCategorySelection.selectedSubCategories = [.all]
            } else if let firstAllowed = allowed.first {
                subCategorySelection.selectedSubCategories = [firstAllowed]
            }
        }
    }
}
