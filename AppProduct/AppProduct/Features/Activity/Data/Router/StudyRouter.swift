//
//  StudyRouter.swift
//  AppProduct
//
//  Created by Codex on 2/18/26.
//

import Foundation
internal import Alamofire
import Moya

/// Study Feature API 라우터
enum StudyRouter {
    case getCurriculum(part: String)
    case getCurriculumWeeks(part: String)
    case getMyProgress
    case submitWorkbook(challengerWorkbookId: Int, body: WorkbookSubmissionRequestDTO)
}

extension StudyRouter: BaseTargetType {
    var path: String {
        switch self {
        case .getCurriculum:
            return "/api/v1/curriculums"
        case .getCurriculumWeeks:
            return "/api/v1/curriculums/weeks"
        case .getMyProgress:
            return "/api/v1/curriculums/challengers/me/progress"
        case .submitWorkbook(let challengerWorkbookId, _):
            return "/api/v1/challenger-workbooks/\(challengerWorkbookId)/submissions"
        }
    }

    var method: Moya.Method {
        switch self {
        case .submitWorkbook:
            return .post
        case .getCurriculum, .getCurriculumWeeks, .getMyProgress:
            return .get
        }
    }

    var task: Task {
        switch self {
        case .getCurriculum(let part), .getCurriculumWeeks(let part):
            return .requestParameters(
                parameters: ["part": part],
                encoding: URLEncoding.queryString
            )
        case .getMyProgress:
            return .requestPlain
        case .submitWorkbook(_, let body):
            return .requestJSONEncodable(body)
        }
    }
}
