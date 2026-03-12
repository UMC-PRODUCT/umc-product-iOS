//
//  ScheduleData.swift
//  AppProduct
//
//  Created by euijjang97 on 1/18/26.
//

import Foundation

protocol ScheduleDDayDisplayable {
    var dDay: Int { get }
}

extension ScheduleDDayDisplayable {
    /// 서버의 dDay 부호 규칙에 맞춰 화면 표시용 문자열을 반환합니다.
    ///
    /// 양수는 미래 일정(D-N), 음수는 지난 일정(D+N), 0은 오늘 일정(D-Day)입니다.
    var dDayText: String {
        if dDay > 0 {
            return "D-\(dDay)"
        }
        if dDay < 0 {
            return "D+\(abs(dDay))"
        }
        return "D-Day"
    }
}

/// 달력 스케줄 리스트 데이터 모델
///
/// 특정 날짜에 선택된 일정들을 리스트 형태로 표시할 때 사용되는 일정 데이터입니다.
struct ScheduleData: Equatable, Identifiable, ScheduleDDayDisplayable {

    /// 고유 식별자
    var id: Int { scheduleId }

    /// 일정 서버 ID
    let scheduleId: Int

    /// 일정 제목
    let title: String

    /// 일정 시작 시간
    let startsAt: Date

    /// 일정 종료 시간
    let endsAt: Date

    /// 참여 상태 (예: "참여 예정")
    let status: String

    /// D-Day 값 (양수: 미래, 음수: 과거)
    let dDay: Int
}
