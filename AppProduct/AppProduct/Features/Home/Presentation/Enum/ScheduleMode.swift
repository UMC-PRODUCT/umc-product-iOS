//
//  ScheduleMode.swift
//  AppProduct
//
//  Created by euijjang97 on 1/15/26.
//

import Foundation

/// 일정 캘린더 표시 모드
///
/// 캘린더가 가로 스크롤(Horizon) 모드인지, 월별 그리드(Grid) 모드인지 정의합니다.
enum ScheduleMode {
    /// 가로 스크롤 모드 (주 단위 이동 등에 사용)
    case horizon
    /// 월별 그리드 모드 (달력 형태)
    case grid
}
