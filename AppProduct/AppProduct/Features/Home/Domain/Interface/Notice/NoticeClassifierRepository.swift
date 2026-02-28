//
//  NoticeClassifierRepository.swift
//  AppProduct
//
//  Created by euijjang97 on 1/21/26.
//

import Foundation

/// 알림 분류기 리포지토리 프로토콜
///
/// 알림 내용을 분석하여 적절한 알림 타입(`NoticeAlarmType`)으로 분류하는 기능을 정의합니다.
/// CoreML 모델 또는 키워드 분석 방식을 사용할 수 있습니다.
protocol NoticeClassifierRepository {
    
    /// 분류 모델을 로드합니다.
    func loadModel() throws
    
    /// CoreML 모델을 사용하여 텍스트를 분석하고 알림 타입을 반환합니다.
    /// - Parameter text: 분석할 텍스트 (제목 또는 내용)
    /// - Returns: 분류된 알림 타입 (실패 시 nil)
    func classifyWithML(text: String) -> NoticeAlarmType?
    
    /// 키워드 매칭 방식을 사용하여 텍스트를 분석하고 알림 타입을 반환합니다.
    /// - Parameter text: 분석할 텍스트
    /// - Returns: 분류된 알림 타입 (기본값 포함)
    func classifyWithKeywords(text: String) -> NoticeAlarmType
}
