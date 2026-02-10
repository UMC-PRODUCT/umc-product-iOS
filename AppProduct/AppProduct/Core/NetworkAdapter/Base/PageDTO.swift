//
//  PageDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/10/26.
//

import Foundation

// MARK: - PageDTO

/// Spring Boot Pageable 공통 응답 DTO (Offset 기반)
///
/// - Note: 여러 Feature에서 재사용되는 제네릭 페이지네이션 응답
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

// MARK: - CursorDTO

/// Cursor 기반 페이지네이션 공통 응답 DTO
///
/// - Note: 여러 Feature에서 재사용되는 제네릭 커서 페이지네이션 응답
struct CursorDTO<T: Codable>: Codable {
    /// 현재 페이지 항목 목록
    let content: [T]
    /// 다음 페이지 조회용 커서 값 (마지막 페이지 시 nil)
    let nextCursor: Int?
    /// 다음 페이지 존재 여부
    let hasNext: Bool
}
