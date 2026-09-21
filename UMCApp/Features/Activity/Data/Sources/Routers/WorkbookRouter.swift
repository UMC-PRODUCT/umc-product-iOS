//
//  WorkbookRouter.swift
//  ActivityData
//
//  Created by euijjang97 on 9/21/26.
//

import ActivityDomain
internal import Alamofire
import CoreNetwork
import Foundation
import Moya

struct WorkbookProgressQuery: Sendable {
    let gisuId: String
    var toParameters: [String: Any] { ["gisuId": gisuId] }
}

struct MissionSubmissionRequestDTO: Encodable, Sendable {
    let originalWorkbookMissionId: Int
    let challengerMissionId: Int
    let content: String?
}

struct MissionFeedbackRequestDTO: Encodable, Sendable {
    let missionSubmissionId: Int
    let content: String
    let result: String
}

enum WorkbookRouter: BaseTargetType, Sendable {
    case progress(WorkbookProgressQuery)
    case challenger(String)
    case original(String)
    case submit(MissionSubmissionRequestDTO)
    case feedback(MissionFeedbackRequestDTO)
    case editSubmission(String, String)
    case withdraw(String)
    case editFeedback(String, String)
    case deleteFeedback(String)

    var path: String {
        let root = "/api/v2/curriculums"
        let missions = root + "/challenger-workbooks/missions"
        switch self {
        case .progress: return root + "/progress/me"
        case .challenger(let id): return root + "/challenger-workbooks/\(id)"
        case .original(let id): return root + "/original-workbooks/\(id)"
        case .submit: return missions
        case .feedback: return missions + "/feedback"
        case .editSubmission(let id, _), .withdraw(let id): return missions + "/\(id)"
        case .editFeedback(let id, _), .deleteFeedback(let id):
            return missions + "/feedback/\(id)"
        }
    }
    var method: Moya.Method {
        switch self {
        case .progress, .challenger, .original: return .get
        case .submit, .feedback: return .post
        case .editSubmission, .editFeedback: return .patch
        case .withdraw, .deleteFeedback: return .delete
        }
    }
    var task: Moya.Task {
        switch self {
        case .progress(let query):
            return .requestParameters(
                parameters: query.toParameters, encoding: URLEncoding.queryString)
        case .submit(let body): return .requestJSONEncodable(body)
        case .feedback(let body): return .requestJSONEncodable(body)
        case .editSubmission(_, let content), .editFeedback(_, let content):
            return .requestData(Data(content.utf8))
        default: return .requestPlain
        }
    }
    var headers: [String: String]? {
        var headers = NetworkConfig.defaultHeaders
        headers["Content-Type"] =
            method == .patch
            ? "text/plain; charset=utf-8" : "application/json"
        return headers
    }
}
