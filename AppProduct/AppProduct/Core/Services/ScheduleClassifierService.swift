//
//  ScheduleClassifierService.swift
//  AppProduct
//
//  Created by euijjang97 on 1/21/26.
//

import Foundation

/// 싱글톤 래퍼 - 간편하게 사용할 수 있도록
final class ScheduleClassifierService {
    static let shared = ScheduleClassifierService()

    private let useCase: ClassifyScheduleUseCase

    private init() {
        let repository = ScheduleClassifierRepositoryImpl()
        self.useCase = ClassifyScheduleUseCaseImpl(repository: repository)
    }

    /// 일정 제목을 분류합니다
    /// - Parameter title: 일정 제목
    /// - Returns: 분류된 카테고리
    func classifySchedule(title: String) async -> ScheduleIconCategory {
        await useCase.execute(title: title)
    }
}
