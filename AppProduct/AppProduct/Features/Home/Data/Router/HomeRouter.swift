//
//  HomeRouter.swift
//  AppProduct
//
//  Created by euijjang97 on 2/11/26.
//

import Foundation
internal import Alamofire
import Moya

/// 홈 Feature API 라우터
///
/// 홈 대시보드에 필요한 API 엔드포인트를 정의합니다.
enum HomeRouter {
    /// 내 프로필 조회 (기수 + 역할 정보)
    case getGen
    /// 챌린저 패널티 조회
    case getPenalty(id: Int)
    /// 월별 내 일정 조회
    case getSchedules(year: Int, month: Int)
    /// 최근 공지사항 조회
    case getNoticeRecent(query: NoticeListRequestDTO)
}

extension HomeRouter: BaseTargetType {

    // MARK: - Path

    var path: String {
        switch self {
        case .getGen:
            return "/api/v1/member/me"
        case .getPenalty(let id):
            return "/api/v1/challenger/\(id)"
        case .getSchedules:
            return "/api/v1/schedules/my-list"
        case .getNoticeRecent:
            return "/api/v1/notices"
        }
    }

    // MARK: - Method

    var method: Moya.Method {
        switch self {
        case .getGen, .getPenalty, .getSchedules, .getNoticeRecent:
            return .get
        }
    }

    // MARK: - Task

    var task: Moya.Task {
        switch self {
        case .getGen, .getPenalty:
            return .requestPlain
        case .getSchedules(let year, let month):
            return .requestParameters(
                parameters: ["year": year, "month": month],
                encoding: URLEncoding.queryString
            )
        case .getNoticeRecent(let query):
            return .requestParameters(
                parameters: query.queryItems,
                encoding: URLEncoding.queryString
            )
        }
    }
}
