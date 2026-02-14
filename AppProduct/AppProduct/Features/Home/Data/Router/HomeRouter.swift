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
    /// 월별 내 일정 조회
    case getSchedules(year: Int, month: Int)
    /// 최근 공지사항 조회
    case getNoticeRecent(query: NoticeListRequestDTO)
    /// FCM 토큰 등록/갱신
    case postFCMToken(challengerId: Int, request: RegisterFCMTokenRequestDTO)
}

extension HomeRouter: BaseTargetType {

    // MARK: - Path
    var path: String {
        switch self {
        case .getGen:
            return "/api/v1/member/me"
        case .getSchedules:
            return "/api/v1/schedules/my-list"
        case .getNoticeRecent:
            return "/api/v1/notices"
        case .postFCMToken(let challengerId, _):
            return "/api/v1/notification/fcm/\(challengerId)"
        }
    }

    // MARK: - Method

    var method: Moya.Method {
        switch self {
        case .getGen, .getSchedules, .getNoticeRecent:
            return .get
        case .postFCMToken:
            return .post
        }
    }

    // MARK: - Task

    var task: Moya.Task {
        switch self {
        case .getGen:
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
        case .postFCMToken(_, let request):
            return .requestJSONEncodable(request)
        }
    }
}
