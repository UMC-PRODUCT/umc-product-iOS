//
//  StudyGroupNamesDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/18/26.
//

import Foundation

/// 로그인한 유저의 스터디 그룹 id/이름 목록 응답 DTO
///
/// `GET /api/v1/study-groups/names`
struct StudyGroupNamesDTO: Codable, Sendable, Equatable {
    let studyGroups: [StudyGroupNameItemDTO]
}

struct StudyGroupNameItemDTO: Codable, Sendable, Equatable {
    let groupId: Int
    let name: String
}

extension StudyGroupNamesDTO {
    func toDomain() -> [StudyGroupItem] {
        let groups = studyGroups.map { item in
            StudyGroupItem(
                serverID: String(item.groupId),
                name: item.name,
                iconName: "person.2.fill",
                part: nil
            )
        }
        return [.all] + groups
    }
}
