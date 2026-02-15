//
//  NoticeListRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/11/26.
//

import Foundation

/// 홈 화면 최근 공지 Request DTO
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
    /// 정렬 기준
    let sort: [String]

    init(
        gisuId: Int,
        chapterId: Int? = nil,
        schoolId: Int? = nil,
        part: UMCPartType? = nil,
        page: Int = 0,
        size: Int = 10,
        sort: [String] = ["createdAt,DESC"]
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
            "size": size
        ]
        if !sort.isEmpty {
            params["sort"] = sort
        }
        if let chapterId { params["chapterId"] = chapterId }
        if let schoolId { params["schoolId"] = schoolId }
        if let part { params["part"] = part.apiValue }
        return params
    }
}

/// 홈 화면 최근 공지 Response DTO
struct NoticeListResponseDTO: Codable {
    let id: String
    let title: String
    let content: String
    let shouldSendNotification: Bool
    let viewCount: String
    let createdAt: String
    let targetInfo: TargetInfoDTO
    let authorChallengerId: String
    let authorNickname: String
    let authorName: String
}

// MARK: - toDomain

extension NoticeListResponseDTO {
    /// DTO → RecentNoticeData 변환
    func toRecentNoticeData() -> RecentNoticeData {
        let category: RecentCategory
        if targetInfo.targetSchoolId != nil {
            category = .univ
        } else if targetInfo.targetChapterId != nil {
            category = .oranization
        } else {
            category = .operationsTeam
        }

        let date = ISO8601DateFormatter().date(from: createdAt) ?? Date()

        return RecentNoticeData(
            category: category,
            title: title,
            createdAt: date
        )
    }
}

// MARK: - TargetInfoDTO

struct TargetInfoDTO: Codable {
    let targetGisuId: Int
    let targetChapterId: Int?
    let targetSchoolId: Int?
    let targetParts: UMCPartType?
}

// MARK: - PageDTO

/// Spring Boot Pageable 공통 응답 DTO (Offset 기반)
struct PageDTO<T: Codable>: Codable {
    /// 현재 페이지 항목 목록
    let content: [T]
    /// 현재 페이지 번호 (0부터 시작)
    let page: Int
    /// 한 페이지 항목 수
    let size: Int
    /// 전체 항목 수
    let totalElements: Int
    /// 전체 페이지 수
    let totalPages: Int
    /// 다음 페이지 존재 여부
    let hasNext: Bool
    /// 이전 페이지 존재 여부
    let hasPrevious: Bool
}

