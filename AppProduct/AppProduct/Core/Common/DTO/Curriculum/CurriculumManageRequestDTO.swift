
//
//  CurriculumManageRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/10/26.
//

import Foundation

// MARK: - Manage Curriculums

/// 커리큘럼 관리 (생성/수정/삭제) 요청 DTO
///
/// `PUT /api/v1/curriculums` 요청 Body
struct ManageCurriculumRequestDTO: Encodable {
    let week: Int
    let part: String
    let status: String
    /// 기타 필요한 프로퍼티 추가 필요 (예시)
    
    // Note: 실제 API 스펙에 맞춰 필드 추가 필요. 
    // 현재 parameters: [String: Any] 로 되어 있어서 정확한 필드를 알 수 없음.
    // 일단 Encodable로 기본 구조만 잡음.
}
