//
//  ScheduleRouter.swift
//  AppProduct
//
//  Created by Claude on 2/12/26.
//

import Foundation
internal import Alamofire
import Moya

/// 일정 Feature API 라우터
///
/// 일정 생성/관리에 필요한 API 엔드포인트를 정의합니다.
enum ScheduleRouter {
    /// 출석 포함 일정 생성
    case postGenerateSchedule(schedule: GenerateScheduleRequetDTO)
}

extension ScheduleRouter: BaseTargetType {

    // MARK: - Path

    var path: String {
        switch self {
        case .postGenerateSchedule:
            return "/api/v1/schedules/with-attendance"
        }
    }

    // MARK: - Method

    var method: Moya.Method {
        switch self {
        case .postGenerateSchedule:
            return .post
        }
    }

    // MARK: - Task

    var task: Moya.Task {
        switch self {
        case .postGenerateSchedule(let schedule):
            return .requestJSONEncodable(schedule)
        }
    }
}
