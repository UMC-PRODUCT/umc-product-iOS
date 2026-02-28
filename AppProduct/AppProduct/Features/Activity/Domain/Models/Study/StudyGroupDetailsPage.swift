//
//  StudyGroupDetailsPage.swift
//  AppProduct
//
//  Created by euijjang97 on 2/24/26.
//

import Foundation

/// 스터디 그룹 상세 페이지 결과 모델
///
/// cursor 기반 페이지네이션 정보를 함께 제공합니다.
struct StudyGroupDetailsPage: Equatable {
    let content: [StudyGroupInfo]
    let hasNext: Bool
    let nextCursor: Int?
}

