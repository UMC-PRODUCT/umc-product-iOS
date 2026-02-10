
//
//  CurriculumRouter.swift
//  AppProduct
//
//  Created by euijjang97 on 2/10/26.
//

import Foundation
import Moya
internal import Alamofire

/// 커리큘럼 API 라우터
///
/// 커리큘럼 조회, 워크북 제출, 커리큘럼 관리 API를 정의합니다.
enum CurriculumRouter {
    // MARK: - GET

    /// 파트별 커리큘럼 조회
    case getCurriculums(query: PartQuery)
    /// 워크북 제출 현황 조회
    case getWorkbookSubmissions(query: CurriculumWorkbook)
    /// 파트별 커리큘럼 주차 목록 조회
    case getWeeks(query: PartQuery)
    /// 필터용 스터디 그룹 목록 조회
    case getStudyGroups(query: StudyGroupFilterQuery)
    /// 내 커리큘럼 진행 상황 조회
    case getMyProgress
    /// 배포된 주차 번호 목록 조회
    case getAvailableWeeks(parameters: [String: Any]) 

    // MARK: - POST

    /// 워크북 제출
    /// - Important: PENDING 상태의 워크북만 제출 가능. 한 번 제출하면 수정 불가.
    case submitWorkbook(challengerWorkbookId: Int, body: SubmitWorkbookRequestDTO)

    // MARK: - PUT

    /// 커리큘럼 관리 (생성/수정/삭제)
    case manageCurriculums(parameters: [String: Any])
}

// MARK: - BaseTargetType

extension CurriculumRouter: BaseTargetType {

    // MARK: - Property

    var path: String {
        switch self {
        case .getCurriculums, .manageCurriculums:
            return "/api/v1/curriculums"
        case .getWorkbookSubmissions:
            return "/api/v1/curriculums/workbook-submissions"
        case .getWeeks:
            return "/api/v1/curriculums/weeks"
        case .getStudyGroups:
            return "/api/v1/curriculums/study-groups"
        case .getMyProgress:
            return "/api/v1/curriculums/challengers/me/progress"
        case .getAvailableWeeks:
            return "/api/v1/curriculums/available-weeks"
        case .submitWorkbook(let challengerWorkbookId, _):
            return "/api/v1/challenger-workbooks/\(challengerWorkbookId)/submissions"
        }
    }

    var method: Moya.Method {
        switch self {
        case .getCurriculums, .getWorkbookSubmissions, .getWeeks,
             .getStudyGroups, .getMyProgress, .getAvailableWeeks:
            return .get
        case .submitWorkbook:
            return .post
        case .manageCurriculums:
            return .put
        }
    }

    var task: Moya.Task {
        switch self {
        case .getMyProgress:
            return .requestPlain

        case .getCurriculums(let query):
            return .requestParameters(parameters: query.toParameters, encoding: URLEncoding.queryString)

        case .getWorkbookSubmissions(let query):
            return .requestParameters(parameters: query.toParameters, encoding: URLEncoding.queryString)

        case .getWeeks(let query):
            return .requestParameters(parameters: query.toParameters, encoding: URLEncoding.queryString)

        case .getStudyGroups(let query):
            return .requestParameters(
                parameters: query.toParameters,
                encoding: URLEncoding.queryString
            )

        case .getAvailableWeeks(let parameters):
            return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)

        case .submitWorkbook(_, let body):
            return .requestJSONEncodable(body)

        case .manageCurriculums(let parameters):
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        }
    }
}

