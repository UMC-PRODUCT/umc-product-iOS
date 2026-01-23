//
//  ScheduleData.swift
//  AppProduct
//
//  Created by euijjang97 on 1/18/26.
//

import Foundation

/// 달력 스케줄 리스트 데이터
struct ScheduleData: Equatable, Identifiable {
    var id: UUID = .init()
    let title: String
    let subTitle: String
}
