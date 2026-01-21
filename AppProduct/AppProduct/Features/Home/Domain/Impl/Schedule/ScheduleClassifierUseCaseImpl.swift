//
//  ScheduleClassifierUseCaseImpl.swift
//  AppProduct
//
//  Created by euijjang97 on 1/21/26.
//

import Foundation

final class ClassifyScheduleUseCaseImpl: ClassifyScheduleUseCase {
    private let repository: ScheduleClassifierRepository

    init(repository: ScheduleClassifierRepository) {
        self.repository = repository
    }

    func execute(title: String) async -> ScheduleIconCategory {
        if let cached = repository.getCachedCategory(for: title) {
            print("캐시에서 가져옴: \(title) → \(cached.rawValue)")
            return cached
        }

        if repository.isModelLoaded, let mlResult = repository.classifyWithML(title: title) {
            print("CoreML 분류: \(title) → \(mlResult.rawValue)")
            repository.cacheCategory(mlResult, for: title)
            return mlResult
        }

        let keywordResult = repository.classifyWithKeywords(title: title)
        print("키워드 기반 분류: \(title) → \(keywordResult.rawValue)")
        repository.cacheCategory(keywordResult, for: title)
        return keywordResult
    }
}
