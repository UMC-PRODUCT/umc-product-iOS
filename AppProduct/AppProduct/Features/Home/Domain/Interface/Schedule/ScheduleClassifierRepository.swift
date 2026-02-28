//
//  ScheduleClassifierRepository.swift
//  AppProduct
//
//  Created by euijjang97 on 1/21/26.
//

import Foundation

/// 일정 분류 리포지토리 프로토콜
///
/// 일정 제목을 분석하여 적절한 카테고리(`ScheduleIconCategory`)로 분류하는 기능을 정의합니다.
/// CoreML, 키워드 매칭, 캐싱 기능을 제공합니다.
protocol ScheduleClassifierRepository {
    /// CoreML 모델을 로드합니다
    func loadModel() throws

    /// CoreML 모델로 일정 제목을 카테고리로 분류합니다
    /// - Parameter title: 일정 제목
    /// - Returns: 분류된 ScheduleIconCategory
    func classifyWithML(title: String) -> ScheduleIconCategory?

    /// 키워드 기반으로 일정 제목을 분류합니다
    /// - Parameter title: 일정 제목
    /// - Returns: 분류된 ScheduleIconCategory
    func classifyWithKeywords(title: String) -> ScheduleIconCategory

    /// 캐시에서 카테고리를 가져옵니다
    /// - Parameter title: 일정 제목
    /// - Returns: 캐시된 카테고리 (없으면 nil)
    func getCachedCategory(for title: String) -> ScheduleIconCategory?

    /// 카테고리를 캐시에 저장합니다
    /// - Parameters:
    ///   - category: 저장할 카테고리
    ///   - title: 일정 제목
    func cacheCategory(_ category: ScheduleIconCategory, for title: String)

    /// 모델 로드 상태
    var isModelLoaded: Bool { get }
}
