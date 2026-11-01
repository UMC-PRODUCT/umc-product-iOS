// Created by euijjang97 on 11/1/26.
import Foundation
import ActivityDomain

/// 검색 조건은 빈 선택지를 전송하지 않습니다.
struct MemberAdministrationQuery: Sendable {
    let filter: MemberSearchFilter
    let page: Int

    var toParameters: [String: Any] {
        var parameters: [String: Any] = ["page": page, "size": 20]
        let values = [
            "keyword": filter.keyword, "gisuId": filter.gisuId,
            "chapterId": filter.chapterId, "schoolId": filter.schoolId, "part": filter.part
        ]
        for (key, value) in values {
            if let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                parameters[key] = value
            }
        }
        return parameters
    }
}

struct MemberOrganizationQuery: Sendable {
    let gisuId: String
    var toParameters: [String: Any] {
        ["id": gisuId, "includeChapter": true, "includeSchool": true]
    }
}

struct UpdatePointDescriptionRequestDTO: Encodable, Sendable {
    let newDescription: String
}
