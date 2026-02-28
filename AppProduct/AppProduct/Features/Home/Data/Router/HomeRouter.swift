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
    /// 일정 상세 조회
    case getScheduleDetail(scheduleId: Int)
    /// 최근 공지사항 조회
    case getNoticeRecent(query: NoticeListRequestDTO)
    /// 기수 상세 조회
    case getGisuDetail(gisuId: Int)
    /// FCM 토큰 등록/갱신
    case putFCMToken(request: RegisterFCMTokenRequestDTO)
}

extension HomeRouter: BaseTargetType {

    // MARK: - Path
    var path: String {
        switch self {
        case .getGen:
            return "/api/v1/member/me"
        case .getSchedules:
            return "/api/v1/schedules/my-list"
        case .getScheduleDetail(let scheduleId):
            return "/api/v1/schedules/\(scheduleId)"
        case .getNoticeRecent:
            return "/api/v1/notices"
        case .getGisuDetail(let gisuId):
            return "/api/v1/gisu/\(gisuId)"
        case .putFCMToken:
            return "/api/v1/notification/fcm/token"
        }
    }

    // MARK: - Method

    var method: Moya.Method {
        switch self {
        case .getGen, .getSchedules, .getScheduleDetail, .getNoticeRecent, .getGisuDetail:
            return .get
        case .putFCMToken:
            return .put
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
        case .getScheduleDetail:
            return .requestPlain
        case .getNoticeRecent(let query):
            return .requestParameters(
                parameters: query.queryItems,
                encoding: URLEncoding.queryString
            )
        case .getGisuDetail:
            return .requestPlain
        case .putFCMToken(let request):
            return .requestJSONEncodable(request)
        }
    }
}
