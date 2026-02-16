//
//  NoticeEditorTargetRouter.swift
//  AppProduct
//
//  Created by euijjang97 on 2/16/26.
//

import Foundation
import Moya
internal import Alamofire

/// 공지 에디터 타겟(지부/학교) 목록 조회용 API 라우터
enum NoticeEditorTargetRouter: BaseTargetType {

    // MARK: - Case

    /// 전체 지부 목록 조회
    case getAllChapters
    /// 전체 학교 목록 조회
    case getAllSchools
    /// 기수별 지부 및 소속 학교 목록 조회
    case getChaptersWithSchools(gisuId: Int)

    // MARK: - BaseTargetType

    /// API 경로
    var path: String {
        switch self {
        case .getAllChapters:
            return "/api/v1/chapters"
        case .getAllSchools:
            return "/api/v1/schools/all"
        case .getChaptersWithSchools:
            return "/api/v1/chapters/with-schools"
        }
    }

    /// HTTP 메서드
    var method: Moya.Method {
        switch self {
        case .getAllChapters, .getAllSchools, .getChaptersWithSchools:
            return .get
        }
    }

    /// 요청 파라미터 구성
    var task: Task {
        switch self {
        case .getAllChapters, .getAllSchools:
            return .requestPlain
        case .getChaptersWithSchools(let gisuId):
            return .requestParameters(
                parameters: ["gisuId": gisuId],
                encoding: URLEncoding.queryString
            )
        }
    }
}
