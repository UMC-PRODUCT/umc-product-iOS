//
//  StudyRouter.swift
//  AppProduct
//
//  Created by euijjang97 on 2/18/26.
//

import Foundation
internal import Alamofire
import Moya

/// Study Feature API 라우터
enum StudyRouter {
    case getCurriculum(part: String)
    case getCurriculumWeeks(part: String)
    case createStudyGroupSchedule(body: StudyGroupScheduleCreateRequestDTO)
    case getMyStudyGroups(cursor: Int?, size: Int)
    case getStudyGroupNames
    case getStudyGroupDetail(groupId: Int)
    case getMemberProfile(memberId: Int)
    case getWorkbookSubmissions(
        weekNo: Int,
        studyGroupId: Int?,
        cursor: Int?,
        size: Int
    )
    case getMyProgress
    case getWorkbookSubmission(challengerWorkbookId: Int)
    case submitWorkbook(challengerWorkbookId: Int, body: WorkbookSubmissionRequestDTO)
    case reviewWorkbook(challengerWorkbookId: Int, body: WorkbookReviewRequestDTO)
    case selectBestWorkbook(challengerWorkbookId: Int, body: BestWorkbookSelectionRequestDTO)
    case createStudyGroup(body: StudyGroupCreateRequestDTO)
    case updateStudyGroup(groupId: Int, body: StudyGroupUpdateRequestDTO)
    case deleteStudyGroup(groupId: Int)
}

extension StudyRouter: BaseTargetType {
    var path: String {
        switch self {
        case .getCurriculum:
            return "/api/v1/curriculums"
        case .getCurriculumWeeks:
            return "/api/v1/curriculums/weeks"
        case .createStudyGroupSchedule:
            return "/api/v1/schedules/study-group"
        case .getMyStudyGroups:
            return "/api/v1/study-groups"
        case .getStudyGroupNames:
            return "/api/v1/study-groups/names"
        case .getStudyGroupDetail(let groupId):
            return "/api/v1/study-groups/\(groupId)"
        case .getMemberProfile(let memberId):
            return "/api/v1/member/profile/\(memberId)"
        case .getWorkbookSubmissions:
            return "/api/v1/curriculums/workbook-submissions"
        case .getMyProgress:
            return "/api/v1/curriculums/challengers/me/progress"
        case .getWorkbookSubmission(let challengerWorkbookId):
            return "/api/v1/workbooks/challenger/\(challengerWorkbookId)/submissions"
        case .submitWorkbook(let challengerWorkbookId, _):
            return "/api/v1/challenger-workbooks/\(challengerWorkbookId)/submissions"
        case .reviewWorkbook(let challengerWorkbookId, _):
            return "/api/v1/workbooks/challenger/\(challengerWorkbookId)/review"
        case .selectBestWorkbook(let challengerWorkbookId, _):
            return "/api/v1/workbooks/challenger/\(challengerWorkbookId)/best"
        case .createStudyGroup:
            return "/api/v1/study-groups"
        case .updateStudyGroup(let groupId, _):
            return "/api/v1/study-groups/\(groupId)"
        case .deleteStudyGroup(let groupId):
            return "/api/v1/study-groups/\(groupId)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .submitWorkbook:
            return .post
        case .reviewWorkbook:
            return .post
        case .selectBestWorkbook:
            return .patch
        case .createStudyGroup:
            return .post
        case .createStudyGroupSchedule:
            return .post
        case .updateStudyGroup:
            return .patch
        case .deleteStudyGroup:
            return .delete
        case .getCurriculum,
             .getCurriculumWeeks,
             .getMyStudyGroups,
             .getStudyGroupNames,
             .getStudyGroupDetail,
             .getMemberProfile,
             .getWorkbookSubmissions,
             .getMyProgress,
             .getWorkbookSubmission:
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
        case .createStudyGroupSchedule(let body):
            return .requestJSONEncodable(body)
        case .getMyStudyGroups(let cursor, let size):
            var parameters: [String: Any] = [
                "size": size
            ]
            if let cursor {
                parameters["cursor"] = cursor
            }
            return .requestParameters(
                parameters: parameters,
                encoding: URLEncoding.queryString
            )
        case .getWorkbookSubmissions(let weekNo, let studyGroupId, let cursor, let size):
            var parameters: [String: Any] = [
                "weekNo": weekNo,
                "size": size
            ]
            if let studyGroupId {
                parameters["studyGroupId"] = studyGroupId
            }
            if let cursor {
                parameters["cursor"] = cursor
            }
            return .requestParameters(
                parameters: parameters,
                encoding: URLEncoding.queryString
            )
        case .getStudyGroupNames,
             .getStudyGroupDetail,
             .getMemberProfile,
             .getMyProgress,
             .getWorkbookSubmission:
            return .requestPlain
        case .submitWorkbook(_, let body):
            return .requestJSONEncodable(body)
        case .reviewWorkbook(_, let body):
            return .requestJSONEncodable(body)
        case .selectBestWorkbook(_, let body):
            return .requestJSONEncodable(body)
        case .createStudyGroup(let body):
            return .requestJSONEncodable(body)
        case .updateStudyGroup(_, let body):
            return .requestJSONEncodable(body)
        case .deleteStudyGroup:
            return .requestPlain
        }
    }
}
