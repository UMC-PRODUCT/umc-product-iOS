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
        let keywordResult = repository.classifyWithKeywords(title: title)
        let forcedRule = forcedRuleCategory(for: title)

        // 2. CoreML 분류 시도
        if repository.isModelLoaded, let mlResult = repository.classifyWithML(title: title) {
            if let forcedRule, forcedRule != mlResult {
                print("ScheduleClassifier [ML+RULE] \(title) -> \(forcedRule.rawValue) (ml=\(mlResult.rawValue))")
                return forcedRule
            }

            print("ScheduleClassifier [ML] \(title) -> \(mlResult.rawValue)")
            return mlResult
        }

        // 3. 키워드 기반 분류 (Fallback)
        print("ScheduleClassifier [KW] \(title) -> \(keywordResult.rawValue)")
        return keywordResult
    }

    /// 모델 예측보다 우선해야 하는 강한 규칙 카테고리
    ///
    /// 예: OT/오리엔테이션/온보딩은 `orientation`으로 고정
    private func forcedRuleCategory(for title: String) -> ScheduleIconCategory? {
        let normalized = title.lowercased()
        let orientationTokens = ["ot", "오티", "오리엔테이션", "온보딩"]

        if orientationTokens.contains(where: { normalized.contains($0) }) {
            return .orientation
        }
        return nil
    }
}
