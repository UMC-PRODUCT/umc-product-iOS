
//
//  ScheduleRouter.swift
//  AppProduct
//
//  Created by euijjang97 on 2/10/26.
//

import Foundation
import Moya
internal import Alamofire

/// 행사 및 스터디 일정 관련 API 라우터
enum ScheduleRouter {
    // MARK: - DELETE
    /// 출석부 비활성화
    case deleteAttendanceSheet(sheetId: Int)
    /// 일정 + 출석부 통합 삭제
    case deleteScheduleWithAttendance(scheduleId: Int)
    
    // MARK: - GET
    /// 일정 목록 조회
    case getSchedules
    /// 일정 상세 조회
    case getSchedule(scheduleId: Int)
    /// 월별 내 일정 캘린더/리스트 조회
    case getMyScheduleList(query: ScheduleListQuery)
    /// 출석 기록 상세 조회
    case getAttendance(recordId: Int)
    /// 승인 대기 출석 조회
    case getPendingAttendances(scheduleId: Int)
    /// 내 출석 이력 조회
    case getAttendanceHistory
    /// 출석 가능한 일정 조회
    case getAvailableAttendances
    
    // MARK: - PATCH
    /// 일정 수정
    case updateSchedule(scheduleId: Int, body: UpdateScheduleRequestDTO)
    /// 일정 출석체크 위치 변경
    case updateScheduleLocation(scheduleId: Int, body: UpdateScheduleLocationRequestDTO)
    /// 출석부 수정
    case updateAttendanceSheet(sheetId: Int, body: UpdateAttendanceSheetRequestDTO)
    
    // MARK: - POST
    /// [삭제 예정, 연동 XX]일정 단독 생성
    case createSchedule(body: CreateScheduleRequestDTO)
    /// 일정 + 출석부 통합 생성
    case createScheduleWithAttendance(body: CreateScheduleWithAttendanceRequestDTO)
    /// 스터디 그룹 일정 생성
    case createStudyGroupSchedule(body: CreateStudyGroupScheduleRequestDTO)
    /// 출석부 활성화
    case activateAttendanceSheet(sheetId: Int)
    /// 출석 반려
    case rejectAttendance(recordId: Int)
    /// 출석 승인
    case approveAttendance(recordId: Int)
    /// 사유 제출 출석
    case submitAttendanceReason(body: SubmitAttendanceReasonRequestDTO)
    /// 출석 체크
    case checkAttendance(body: CheckAttendanceRequestDTO)
}

extension ScheduleRouter: BaseTargetType {
    var path: String {
        switch self {
        case .deleteAttendanceSheet(let sheetId):
            return "/api/v1/schedules/attendance-sheets/\(sheetId)"
        case .deleteScheduleWithAttendance(let scheduleId):
            return "/api/v1/schedules/\(scheduleId)/with-attendance"
        case .getSchedules, .createSchedule:
            return "/api/v1/schedules"
        case .getSchedule(let scheduleId), .updateSchedule(let scheduleId, _):
            return "/api/v1/schedules/\(scheduleId)"
        case .getMyScheduleList:
            return "/api/v1/schedules/my-list"
        case .getAttendance(let recordId):
            return "/api/v1/attendances/\(recordId)"
        case .getPendingAttendances(let scheduleId):
            return "/api/v1/attendances/pending/\(scheduleId)"
        case .getAttendanceHistory:
            return "/api/v1/attendances/history"
        case .getAvailableAttendances:
            return "/api/v1/attendances/available"
        case .updateScheduleLocation(let scheduleId, _):
            return "/api/v1/schedules/\(scheduleId)/location"
        case .updateAttendanceSheet(let sheetId, _):
            return "/api/v1/schedules/attendance-sheets/\(sheetId)"
        case .createScheduleWithAttendance:
            return "/api/v1/schedules/with-attendance"
        case .createStudyGroupSchedule:
            return "/api/v1/schedules/study-group"
        case .activateAttendanceSheet(let sheetId):
            return "/api/v1/schedules/attendance-sheets/\(sheetId)/activate"
        case .rejectAttendance(let recordId):
            return "/api/v1/attendances/\(recordId)/reject"
        case .approveAttendance(let recordId):
            return "/api/v1/attendances/\(recordId)/approve"
        case .submitAttendanceReason:
            return "/api/v1/attendances/reason"
        case .checkAttendance:
            return "/api/v1/attendances/check"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .deleteAttendanceSheet, .deleteScheduleWithAttendance:
            return .delete
        case .getSchedules, .getSchedule, .getMyScheduleList, .getAttendance, .getPendingAttendances, .getAttendanceHistory, .getAvailableAttendances:
            return .get
        case .updateSchedule, .updateScheduleLocation, .updateAttendanceSheet:
             return .patch
        case .createSchedule, .createScheduleWithAttendance, .createStudyGroupSchedule, .activateAttendanceSheet, .rejectAttendance, .approveAttendance, .submitAttendanceReason, .checkAttendance:
            return .post
        }
    }
    
    var task: Moya.Task {
        switch self {
        case .deleteAttendanceSheet, .deleteScheduleWithAttendance, .getSchedules, .getSchedule, .getAttendance, .getPendingAttendances, .getAttendanceHistory, .getAvailableAttendances, .activateAttendanceSheet, .rejectAttendance, .approveAttendance:
            return .requestPlain
        
        case .getMyScheduleList(let query):
            return .requestParameters(parameters: query.toParameters, encoding: URLEncoding.queryString)

        case .updateSchedule(_, let body):
            return .requestJSONEncodable(body)
            
        case .updateScheduleLocation(_, let body):
            return .requestJSONEncodable(body)
            
        case .updateAttendanceSheet(_, let body):
            return .requestJSONEncodable(body)
            
        case .createSchedule(let body):
            return .requestJSONEncodable(body)

        case .createScheduleWithAttendance(let body):
            return .requestJSONEncodable(body)
            
        case .createStudyGroupSchedule(let body):
            return .requestJSONEncodable(body)
            
        case .submitAttendanceReason(let body):
            return .requestJSONEncodable(body)
            
        case .checkAttendance(let body):
            return .requestJSONEncodable(body)
        }
    }
}


