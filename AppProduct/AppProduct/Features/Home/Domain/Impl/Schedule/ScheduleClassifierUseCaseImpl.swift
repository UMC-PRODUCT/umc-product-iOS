//
//  ScheduleClassifierUseCaseImpl.swift
//  AppProduct
//
//  Created by euijjang97 on 1/21/26.
//

import Foundation

/// 일정 분류 유스케이스 구현 클래스
///
/// 1. 캐시 확인
/// 2. CoreML 분류 (모델 로드 시)
/// 3. 키워드 기반 분류
/// 순서로 분류 로직을 수행하며, 분류된 결과는 캐시에 저장하여 재사용합니다.
final class ClassifyScheduleUseCaseImpl: ClassifyScheduleUseCase {
    /// 리포지토리 의존성
    private let repository: ScheduleClassifierRepository

    /// 생성자
    init(repository: ScheduleClassifierRepository) {
        self.repository = repository
    }

    /// 일정 분류 실행
    /// - Parameter title: 분류할 일정 제목
    /// - Returns: 분류된 카테고리
    func execute(title: String) async -> ScheduleIconCategory {
        // 1. 캐시 확인
        if let cached = repository.getCachedCategory(for: title) {
            print("캐시에서 가져옴: \(title) → \(cached.rawValue)")
            return cached
        }

        // 2. CoreML 분류 시도
        if repository.isModelLoaded, let mlResult = repository.classifyWithML(title: title) {
            print("CoreML 분류: \(title) → \(mlResult.rawValue)")
            repository.cacheCategory(mlResult, for: title)
            return mlResult
        }

        // 3. 키워드 기반 분류 (Fallback)
        let keywordResult = repository.classifyWithKeywords(title: title)
        print("키워드 기반 분류: \(title) → \(keywordResult.rawValue)")
        repository.cacheCategory(keywordResult, for: title)
        return keywordResult
    }
}
