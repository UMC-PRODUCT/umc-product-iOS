//
//  ScheduleClassifierUseCase.swift
//  AppProduct
//
//  Created by euijjang97 on 1/21/26.
//

import Foundation

/// 일정 분류 유스케이스 프로토콜
///
/// 일정 제목을 입력받아 비즈니스 로직에 따라 최적의 카테고리를 반환합니다.
protocol ClassifyScheduleUseCase {
    /// 일정 제목을 분석하여 적절한 카테고리를 반환합니다
    /// - Parameter title: 일정 제목
    /// - Returns: 분류된 ScheduleIconCategory
    func execute(title: String) async -> ScheduleIconCategory
}
