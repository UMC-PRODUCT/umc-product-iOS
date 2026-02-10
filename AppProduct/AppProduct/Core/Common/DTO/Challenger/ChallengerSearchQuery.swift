//
//  ChallengerSearchQuery.swift
//  AppProduct
//
//  Created by euijjang97 on 2/10/26.
//

import Foundation

// MARK: - Common Filter

/// 챌린저 검색 공통 필터
///
/// Offset/Cursor 검색에서 공유하는 필터 조건
///
/// - Example:
/// ```swift
/// let filter = ChallengerSearchQuery(nickname: "홍길동", part: "IOS")
/// ```
struct ChallengerSearchQuery {
    /// 특정 챌린저 ID로 정확히 검색
    var challengerId: Int? = nil
    /// 닉네임으로 부분 검색
    var nickname: String? = nil
    /// 소속 학교 ID로 필터링
    var schoolId: Int? = nil
    /// 소속 지부 ID로 필터링
    var chapterId: Int? = nil
    /// 파트별 필터링 (PLAN, DESIGN, WEB, ANDROID, IOS, NODEJS, SPRINGBOOT)
    var part: String? = nil
    /// 기수 ID로 필터링
    var gisuId: Int? = nil

    // MARK: - Function

    /// nil이 아닌 필터만 포함된 쿼리 파라미터 딕셔너리를 반환
    var toParameters: [String: Any] {
        var params: [String: Any] = [:]
        if let challengerId { params["challengerId"] = challengerId }
        if let nickname { params["nickname"] = nickname }
        if let schoolId { params["schoolId"] = schoolId }
        if let chapterId { params["chapterId"] = chapterId }
        if let part { params["part"] = part }
        if let gisuId { params["gisuId"] = gisuId }
        return params
    }
}

// MARK: - Offset Query

/// 챌린저 검색 (Offset 기반) 쿼리
///
/// - Example:
/// ```swift
/// // 기본 검색
/// ChallengerRouter.searchOffset(query: .init())
///
/// // 필터 적용
/// ChallengerRouter.searchOffset(query: .init(
///     page: 1,
///     filter: .init(nickname: "홍길동", part: "IOS")
/// ))
/// ```
struct ChallengerSearchOffsetQuery {
    /// 페이지 인덱스 (0부터 시작)
    var page: Int = 0
    /// 한 페이지 항목 수
    var size: Int = 20
    /// 정렬 기준 (예: ["name,asc"])
    var sort: [String]? = nil
    /// 공통 필터 조건
    var filter: ChallengerSearchQuery = .init()

    // MARK: - Function

    /// 페이지네이션 + 필터를 합친 쿼리 파라미터 딕셔너리를 반환
    var toParameters: [String: Any] {
        var params: [String: Any] = ["page": page, "size": size]
        if let sort { params["sort"] = sort }
        params.merge(filter.toParameters) { _, new in new }
        return params
    }
}

// MARK: - Cursor Query

/// 챌린저 검색 (Cursor 기반) 쿼리
///
/// - Example:
/// ```swift
/// // 첫 페이지 조회
/// ChallengerRouter.searchCursor(query: .init())
///
/// // 다음 페이지 조회
/// ChallengerRouter.searchCursor(query: .init(cursor: lastChallengerId))
/// ```
struct ChallengerSearchCursorQuery {
    /// 이전 페이지의 마지막 챌린저 ID (첫 페이지 시 nil)
    var cursor: Int? = nil
    /// 한 페이지 항목 수
    var size: Int = 20
    /// 공통 필터 조건
    var filter: ChallengerSearchQuery = .init()

    // MARK: - Function

    /// 커서 + 필터를 합친 쿼리 파라미터 딕셔너리를 반환
    var toParameters: [String: Any] {
        var params: [String: Any] = ["size": size]
        if let cursor { params["cursor"] = cursor }
        params.merge(filter.toParameters) { _, new in new }
        return params
    }
}
