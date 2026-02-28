//
//  StudyGroupMembersUpdateRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/26/26.
//

import Foundation

/// 스터디 그룹 멤버 변경 요청 DTO
///
/// `PUT /api/v1/study-groups/{groupId}/members`
struct StudyGroupMembersUpdateRequestDTO: Codable, Sendable, Equatable {
    /// 스터디원 챌린저 ID 목록
    let challengerIds: [Int]
}
