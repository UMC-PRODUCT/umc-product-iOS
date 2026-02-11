//
//  FetchNoticeListRequestDTO.swift
//  AppProduct
//
//  Created by Claude on 2/11/26.
//

import Foundation

struct NoticeListRequestDTO {
    /// 기수 ID (필수)
    let gisuId: Int
    /// 지부 ID (null이면 해당 기수의 전체 공지 조회)
    let chapterId: Int?
    /// 학교 ID (null이면 지부 레벨까지만 필터링)
    let schoolId: Int?
    /// 파트 (null이면 파트 구분 없이 조회)
    let part: UMCPartType?
    /// 페이지 번호 (0부터 시작)
    let page: Int
    /// 페이지 크기
    let size: Int
    /// 정렬 기준 (기본: createdAt,DESC)
    let sort: String

    init(
        gisuId: Int,
        chapterId: Int? = nil,
        schoolId: Int? = nil,
        part: UMCPartType? = nil,
        page: Int = 0,
        size: Int = 20,
        sort: String = "createdAt,DESC"
    ) {
        self.gisuId = gisuId
        self.chapterId = chapterId
        self.schoolId = schoolId
        self.part = part
        self.page = page
        self.size = size
        self.sort = sort
    }

    /// Query Parameter Dictionary 변환
    var queryItems: [String: Any] {
        var params: [String: Any] = [
            "gisuId": gisuId,
            "page": page,
            "size": size,
            "sort": sort
        ]
        if let chapterId { params["chapterId"] = chapterId }
        if let schoolId { params["schoolId"] = schoolId }
        if let part { params["part"] = part.apiValue }
        return params
    }
}
