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

@Observable
final class NoticeEditorViewModel: MultiplePhotoPickerManageable {
    
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
    
    /// 공지사항 제목
    var title: String = ""

    /// 공지사항 본문
    var content: String = ""
    
    /// 투표 폼 시트뷰 표시 여부
    var showVoting: Bool = false
    
    /// 투표 폼 데이터
    var voteFormData: VoteFormData = VoteFormData()
    
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
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !content.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
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
        if isVoteConfirmed {
            alertPrompt = AlertPrompt(
                id: .init(),
                title: "투표가 이미 생성되었습니다",
                message: "투표 카드를 눌러 수정하거나 삭제할 수 있습니다.",
                positiveBtnTitle: "확인"
            )
        } else {
            voteFormData = VoteFormData()
            showVoting = true
        }
    }
    
    func dismissVotingFormSheet() {
        showVoting = false
    }
    
    func confirmVote() {
        isVoteConfirmed = true
    }
    
    func editVote() {
        showVoting = true
    }
    
    func deleteVote() {
        alertPrompt = AlertPrompt(
            id: .init(),
            title: "투표 삭제",
            message: "투표를 삭제하시겠습니까?",
            positiveBtnTitle: "삭제",
            positiveBtnAction: { [weak self] in
                self?.voteFormData = VoteFormData()
                self?.isVoteConfirmed = false
            },
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: true
        )
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
            let item = NoticeImageItem(imageData: nil, isLoading: true)
            loadingItemIds.append(item.id)
            noticeImages.append(item)
        }
        
        for (index, image) in images.enumerated() {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { continue }
            
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초
            
            let loadingId = loadingItemIds[index]
            if let loadingIndex = noticeImages.firstIndex(where: { $0.id == loadingId }) {
                noticeImages[loadingIndex] = NoticeImageItem(imageData: imageData, isLoading: false)
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
