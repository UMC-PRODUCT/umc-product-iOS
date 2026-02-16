//
//  NoticePageDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/16/26.
//

import Foundation

/// 공지 목록/검색 전용 페이지 응답 DTO
///
/// 백엔드에서 숫자 필드를 문자열로 내려주는 스펙에 맞춰
/// page/size/totalElements/totalPages를 String으로 처리합니다.
struct NoticePageDTO<T: Codable>: Codable {
    let content: [T]
    let page: String
    let size: String
    let totalElements: String
    let totalPages: String
    let hasNext: Bool
    let hasPrevious: Bool
}
