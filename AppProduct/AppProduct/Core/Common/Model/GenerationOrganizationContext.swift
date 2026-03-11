//
//  GenerationOrganizationContext.swift
//  AppProduct
//
//  Created by Codex on 3/11/26.
//

import Foundation

/// 기수별 사용자 소속 조직 정보를 저장/복원하기 위한 모델입니다.
struct GenerationOrganizationContext: Codable, Equatable {
    let gen: Int
    let chapterId: Int?
    let chapterName: String?
    let schoolId: Int?
    let schoolName: String?
}
