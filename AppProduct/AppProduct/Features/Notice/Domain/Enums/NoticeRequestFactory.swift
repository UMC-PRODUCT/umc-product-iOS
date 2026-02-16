//
//  NoticeRequestFactory.swift
//  AppProduct
//
//  Created by euijjang97 on 2/16/26.
//

import Foundation

// MARK: - NoticeRequestFactory
/// 공지 목록/검색 요청 DTO를 생성합니다.
enum NoticeRequestFactory {
    /// 메인필터/조직 타입에 따라 적절한 NoticeListRequestDTO를 생성합니다.
    ///
    /// - Parameters:
    ///   - gisuId: 조회할 기수 ID
    ///   - page: 페이지 번호
    ///   - selectedMainFilter: 현재 선택된 메인필터
    ///   - selectedPart: 선택된 파트 (파트 필터 시)
    ///   - organizationType: 사용자 소속 조직 타입
    ///   - chapterId: 사용자 지부 ID
    ///   - schoolId: 사용자 학교 ID
    /// - Returns: API 요청용 DTO
    static func make(
        gisuId: Int,
        page: Int,
        selectedMainFilter: NoticeMainFilterType,
        selectedPart: NoticePart?,
        organizationType: OrganizationType?,
        chapterId: Int,
        schoolId: Int,
        pageSize: Int,
        sort: [String]
    ) -> NoticeListRequestDTO {
        let myChapterId: Int? = chapterId > 0 ? chapterId : nil
        let mySchoolId: Int? = schoolId > 0 ? schoolId : nil

        let requestChapterId: Int?
        let requestSchoolId: Int?
        let requestPart: UMCPartType?

        switch selectedMainFilter {
        case .all:
            switch organizationType {
            case .central:
                requestChapterId = nil
                requestSchoolId = nil
            case .chapter:
                requestChapterId = myChapterId
                requestSchoolId = nil
            case .school:
                requestChapterId = myChapterId
                requestSchoolId = mySchoolId
            default:
                requestChapterId = myChapterId
                requestSchoolId = mySchoolId
            }
            requestPart = nil
        case .central:
            requestChapterId = nil
            requestSchoolId = nil
            requestPart = nil
        case .branch:
            requestChapterId = myChapterId
            requestSchoolId = nil
            requestPart = selectedPart?.umcPartType
        case .school:
            requestChapterId = myChapterId
            requestSchoolId = mySchoolId
            requestPart = selectedPart?.umcPartType
        case .part(let filterPart):
            requestChapterId = myChapterId
            requestSchoolId = mySchoolId
            requestPart = filterPart.umcPartType
        }

        return NoticeListRequestDTO(
            gisuId: gisuId,
            chapterId: requestChapterId,
            schoolId: requestSchoolId,
            part: requestPart,
            page: page,
            size: pageSize,
            sort: sort
        )
    }
}
