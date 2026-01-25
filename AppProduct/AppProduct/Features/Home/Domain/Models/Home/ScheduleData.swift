//
//  ScheduleData.swift
//  AppProduct
//
//  Created by euijjang97 on 1/18/26.
//

import Foundation

/// 달력 스케줄 리스트 데이터
/// 달력 스케줄 리스트 데이터 모델
///
/// 특정 날짜에 선택된 일정들을 리스트 형태로 표시할 때 사용되는 간단한 일정 데이터입니다.
struct ScheduleData: Equatable, Identifiable {
    
    /// 고유 식별자
    var id: UUID = .init()
    
    /// 일정 제목
    let title: String
    
    /// 일정 부제목 (시간 또는 장소 등 요약 정보)
    let subTitle: String
}
