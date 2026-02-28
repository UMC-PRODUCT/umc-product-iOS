//
//  ScheduleRouter.swift
//  AppProduct
//
//  Created by euijjang97 on 2/12/26.
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
    /// 일정 수정
    case patchUpdateSchedule(scheduleId: Int, schedule: UpdateScheduleRequestDTO)
    /// 일정 + 출석부 통합 삭제
    case deleteScheduleWithAttendance(scheduleId: Int)
}

extension ScheduleRouter: BaseTargetType {

    // MARK: - Path

    var path: String {
        switch self {
        case .postGenerateSchedule:
            return "/api/v1/schedules/with-attendance"
        case .patchUpdateSchedule(let scheduleId, _):
            return "/api/v1/schedules/\(scheduleId)"
        case .deleteScheduleWithAttendance(let scheduleId):
            return "/api/v1/schedules/\(scheduleId)/with-attendance"
        }
    }

    // MARK: - Method

    var method: Moya.Method {
        switch self {
        case .postGenerateSchedule:
            return .post
        case .patchUpdateSchedule:
            return .patch
        case .deleteScheduleWithAttendance:
            return .delete
        }
    }

    // MARK: - Task

    var task: Moya.Task {
        switch self {
        case .postGenerateSchedule(let schedule):
            return .requestJSONEncodable(schedule)
        case .patchUpdateSchedule(_, let schedule):
            return .requestJSONEncodable(schedule)
        case .deleteScheduleWithAttendance:
            return .requestPlain
        }
    }
}
