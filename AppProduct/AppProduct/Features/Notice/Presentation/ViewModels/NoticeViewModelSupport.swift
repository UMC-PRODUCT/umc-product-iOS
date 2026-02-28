//
//  NoticeViewModelSupport.swift
//  AppProduct
//
//  Created by euijjang97 on 2/16/26.
//

import Foundation

// MARK: - NoticeUserContext
/// 공지 탭 라벨/필터에 필요한 사용자 컨텍스트입니다.
struct NoticeUserContext {
    let schoolName: String
    let branchName: String
    let part: NoticePart?

    static let empty = NoticeUserContext(
        schoolName: "학교",
        chapterName: "지부",
        responsiblePart: nil
    )

    init(
        schoolName: String,
        chapterName: String,
        responsiblePart: String?
    ) {
        let normalizedSchool = schoolName.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedChapter = chapterName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.schoolName = normalizedSchool.isEmpty ? "학교" : normalizedSchool
        self.branchName = normalizedChapter.isEmpty ? "지부" : normalizedChapter
        self.part = NoticePart(apiValue: responsiblePart ?? "")
    }

}

// MARK: - NoticePagingState
/// 공지 목록/검색 공통 페이징 상태입니다.
struct NoticePagingState {
    private(set) var currentPage: Int = 0
    private(set) var hasNextPage: Bool = false
    private(set) var isLoadingMore: Bool = false

    mutating func begin(page: Int) -> Bool {
        if page == 0 {
            isLoadingMore = false
            return true
        }
        guard hasNextPage, !isLoadingMore else { return false }
        isLoadingMore = true
        return true
    }

    mutating func applySuccess(page: Int, hasNextPage: Bool) {
        currentPage = page
        self.hasNextPage = hasNextPage
        isLoadingMore = false
    }

    mutating func applyFailure() {
        isLoadingMore = false
    }

    mutating func reset() {
        currentPage = 0
        hasNextPage = false
        isLoadingMore = false
    }

    var nextPage: Int {
        currentPage + 1
    }
}
