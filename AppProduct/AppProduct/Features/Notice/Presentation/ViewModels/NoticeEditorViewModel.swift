//
//  NoticeEditorViewModel.swift
//  AppProduct
//
//  Created by 이예지 on 1/24/26.
//

import Foundation

@Observable
final class NoticeEditorViewModel {
    
    // MARK: - Property
    
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
    let availableCategories: [EditorMainCategory]
    
    /// 지부 목록
    let branches: [String]
    
    /// 학교 목록
    let schools: [String]

    /// 투표 폼 시트뷰 표시 여부
    var showVoting: Bool = false

    /// 투표 폼 데이터
    var voteFormData: VoteFormData = VoteFormData()

    // MARK: - Initializer
    
    init(
        userPart: Part?,
        branches: [String] = EditorMockData.branches,
        schools: [String] = EditorMockData.schools
    ) {
        var categories: [EditorMainCategory] = [.central, .branch, .school]
        
        if let part = userPart {
            categories.append(.part(part))
        }
        
        self.availableCategories = categories
        self.selectedCategory = categories.first ?? .central
        self.branches = branches
        self.schools = schools
    }
    
    // MARK: - Function
    
    func selectCategory(_ category: EditorMainCategory) {
        selectedCategory = category
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
    
    func togglePart(_ part: Part) {
        if subCategorySelection.selectedParts.contains(part) {
            subCategorySelection.selectedParts.remove(part)
        } else {
            subCategorySelection.selectedParts.insert(part)
        }
    }
    
    func isSubCategorySelected(_ subCategory: EditorSubCategory) -> Bool {
        subCategorySelection.selectedSubCategories.contains(subCategory)
    }
    
    func isBranchSelected(_ branch: String) -> Bool {
        subCategorySelection.selectedBranches.contains(branch)
    }
    
    func isSchoolSelected(_ school: String) -> Bool {
        subCategorySelection.selectedSchools.contains(school)
    }
    
    func isPartSelected(_ part: Part) -> Bool {
        subCategorySelection.selectedParts.contains(part)
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
        voteFormData = VoteFormData()
        showVoting = true
    }

    func dismissVotingFormSheet() {
        showVoting = false
    }

    func addVoteOption() {
        guard voteFormData.canAddOption else { return }
        voteFormData.options.append(VoteOptionItem())
    }

    func removeVoteOption(_ option: VoteOptionItem) {
        guard voteFormData.canRemoveOption else { return }
        voteFormData.options.removeAll { $0.id == option.id }
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
