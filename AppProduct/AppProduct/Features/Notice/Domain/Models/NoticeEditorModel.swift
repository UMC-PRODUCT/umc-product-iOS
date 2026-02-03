//
//  NoticeEditorModel.swift
//  AppProduct
//
//  Created by 이예지 on 1/24/26.
//

import Foundation

// MARK: - EditorMainCategory
/// 공지 에디터 메인 카테고리
enum EditorMainCategory: Identifiable, Equatable, Hashable {
    case central
    case branch
    case school
    case part(Part)

    var id: String {
        switch self {
        case .central: return "central"
        case .branch: return "branch"
        case .school: return "school"
        case .part(let part): return "part_\(part.id)"
        }
    }

    var labelText: String {
        switch self {
        case .central: return "중앙"
        case .branch: return "지부"
        case .school: return "학교"
        case .part(let part): return part.name
        }
    }

    var labelIcon: String {
        switch self {
        case .central: return "building.columns"
        case .branch: return "mappin.and.ellipse"
        case .school: return "graduationcap"
        case .part: return "person.3.fill"
        }
    }

    /// 서브카테고리 목록
    var subCategories: [EditorSubCategory] {
        switch self {
        case .central:
            return [.all, .staff, .part, .branch]
        case .branch:
            return [.all, .staff, .part, .school]
        case .school:
            return [.all, .staff, .part]
        case .part:
            return []
        }
    }

    /// 서브카테고리가 있는지 여부
    var hasSubCategories: Bool {
        !subCategories.isEmpty
    }
}

// MARK: - EditorSubCategory
/// 공지 에디터 서브 카테고리
enum EditorSubCategory: Identifiable, Equatable, Hashable {
    case all
    case staff
    case branch
    case school
    case part

    var id: String {
        switch self {
        case .all: return "all"
        case .staff: return "staff"
        case .branch: return "branch"
        case .school: return "school"
        case .part: return "part"
        }
    }

    var labelText: String {
        switch self {
        case .all: return "전체"
        case .staff: return "운영진 공지"
        case .branch: return "지부"
        case .school: return "학교"
        case .part: return "파트"
        }
    }

    /// 추가 필터가 필요한지 여부
    var hasFilter: Bool {
        switch self {
        case .branch, .school, .part:
            return true
        case .all, .staff:
            return false
        }
    }
}

// MARK: - EditorSubCategorySelection
/// 서브카테고리 선택 상태
struct EditorSubCategorySelection: Equatable {
    var selectedSubCategories: Set<EditorSubCategory> = [.all]
    var selectedParts: Set<Part> = []
    var selectedBranches: Set<String> = []
    var selectedSchools: Set<String> = []

    /// 선택 요약 텍스트
    var summaryText: String {
        var items: [String] = []

        for subCategory in selectedSubCategories.sorted(by: { $0.id < $1.id }) {
            switch subCategory {
            case .all:
                items.append("전체")
            case .staff:
                items.append("운영진")
            case .branch:
                if selectedBranches.isEmpty {
                    items.append("지부")
                } else {
                    items.append(contentsOf: selectedBranches)
                }
            case .school:
                if selectedSchools.isEmpty {
                    items.append("학교")
                } else {
                    items.append(contentsOf: selectedSchools)
                }
            case .part:
                if selectedParts.isEmpty {
                    items.append("파트")
                } else {
                    items.append(contentsOf: selectedParts.map { $0.name })
                }
            }
        }
        return items.isEmpty ? "선택" : items.joined(separator: ", ")
    }
}

// MARK: - TargetSheetType
/// 게시판 분류별 타겟 설정 sheet(지부, 학교, 파트)
enum TargetSheetType: Identifiable {
    case branch
    case school
    case part
    
    var id: String { String(describing: self) }
    
    var title: String {
        switch self {
        case .branch: return "지부 선택"
        case .school: return "학교 선택"
        case .part: return "파트 선택"
        }
    }
}

// MARK: - LinkItem
/// 링크 첨부 카드
struct NoticeLinkItem: Identifiable, Equatable {
      let id = UUID()
      var link: String = ""
  }

// MARK: - ImageItem
/// 이미지 첨부 카드
struct NoticeImageItem: Identifiable {
    let id = UUID()
    var imageData: Data?
    var isLoading: Bool = false
    
    static func == (lhs: NoticeImageItem, rhs: NoticeImageItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.isLoading == rhs.isLoading
    }
}

// MARK: - VoteOptionItem
/// 투표 옵션 항목
struct VoteOptionItem: Identifiable, Equatable {
    let id = UUID()
    var text: String = ""
}

// MARK: - VoteFormData
/// 투표 폼 데이터
struct VoteFormData: Equatable {
    var options: [VoteOptionItem] = [
        VoteOptionItem(),
        VoteOptionItem()
    ]
    var isAnonymous: Bool = true
    var allowMultipleSelection: Bool = false
    
    static let minOptionCount = 2
    static let maxOptionCount = 5
    
    var canAddOption: Bool {
        options.count < Self.maxOptionCount
    }
    
    var canRemoveOption: Bool {
        options.count > Self.minOptionCount
    }
    
    /// 투표 만들기 완료조건: 위에서부터 연속으로 채워진 항목 개수
    var validOptionsCount: Int {
        var count = 0
        for option in options {
            if option.text.trimmingCharacters(in: .whitespaces).isEmpty {
                break
            }
            count += 1
        }
        return count
    }
    
    /// 투표 확정 가능 여부 (2개 이상 항목이 채워져야 함)
    var canConfirm: Bool {
        validOptionsCount >= 2
    }
}

// MARK: - VoteOptionItem
/// 투표 옵션 항목
struct VoteOptionItem: Identifiable, Equatable {
    let id = UUID()
    var text: String = ""
}

// MARK: - VoteFormData
/// 투표 폼 데이터
struct VoteFormData: Equatable {
    var options: [VoteOptionItem] = [
        VoteOptionItem(),
        VoteOptionItem()
    ]
    var isAnonymous: Bool = true
    var allowMultipleSelection: Bool = false

    static let minOptionCount = 2
    static let maxOptionCount = 10

    var canAddOption: Bool {
        options.count < Self.maxOptionCount
    }

    var canRemoveOption: Bool {
        options.count > Self.minOptionCount
    }
}

// MARK: - EditorMockData
enum EditorMockData {
    static let branches: [String] = ["Nova", "Leo", "Cetus", "Aquarius", "Cassiopeia", "Scorpio", "Pegasus"]
    static let schools: [String] = ["가천대", "강릉원주대", "숭실대"]
}
