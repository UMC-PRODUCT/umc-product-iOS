//
//  ScheduleClassifierUseCase.swift
//  AppProduct
//
//  Created by euijjang97 on 1/21/26.
//

import Foundation

protocol ClassifyScheduleUseCase {
    /// 일정 제목을 분석하여 적절한 카테고리를 반환합니다
    /// - Parameter title: 일정 제목
    /// - Returns: 분류된 ScheduleIconCategory
    func execute(title: String) async -> ScheduleIconCategory
}
