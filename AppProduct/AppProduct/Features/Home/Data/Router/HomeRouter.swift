//
//  HomeRouter.swift
//  AppProduct
//
//  Created by euijjang97 on 2/11/26.
//

import Foundation
internal import Alamofire
import Moya

enum HomeRouter {
    case getGen // 기수 정보 조회
    case getPenalty(id: Int) // 패널티 정보 조회
    case getSchedules // 스케줄 조회
    case postGenerateSchedule(schedule: GenerateScheduleDTO) // 일정 생성
    case getNoticeRecent(query: NoticeListRequestDTO) // 최근 공지 아이템 조회
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
            return "/api/v1/schedules"
        case .postGenerateSchedule:
            return "/api/v1/schedules/with-attendance"
        case .getNoticeRecent:
            return "/api/v1/notices"
        }
    }

    // MARK: - Method

    var method: Moya.Method {
        switch self {
        case .getGen, .getPenalty, .getSchedules, .getNoticeRecent:
            return .get
        case .postGenerateSchedule:
            return .post
        }
    }

    // MARK: - Task

    var task: Moya.Task {
        switch self {
        case .getGen, .getPenalty, .getSchedules:
            return .requestPlain
        case .postGenerateSchedule(let schedule):
            return .requestJSONEncodable(schedule)
        case .getNoticeRecent(let query):
            return .requestParameters(
                parameters: query.queryItems,
                encoding: URLEncoding.queryString
            )
        }
    }
}
