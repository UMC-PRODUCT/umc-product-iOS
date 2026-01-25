//
//  NoticeClassifierUseCaseImpl.swift
//  AppProduct
//
//  Created by euijjang97 on 1/21/26.
//

import Foundation

/// 알림 분류 유스케이스 구현 클래스
///
/// 리포지토리를 사용하여 알림 텍스트를 분석하고 분류합니다.
/// ML 분류를 우선 시도하고, 실패 시 키워드 분류를 수행합니다.
class NoticeClassifierUseCaseImpl: NoticeClassifierUseCase {
    
    /// 알림 분류 리포지토리
    private let repository: NoticeClassifierRepository
    
    /// 생성자
    /// - Parameter repository: 알림 분류 리포지토리 의존성 주입
    init(repository: NoticeClassifierRepository) {
        self.repository = repository
    }
    
    /// 알림 분류를 실행합니다.
    ///
    /// 제목과 내용을 합쳐서 전체 텍스트로 만든 후 분석합니다.
    /// 1. CoreML 모델을 통한 분류 시도
    /// 2. 실패 시 키워드 기반 분류 수행
    ///
    /// - Parameters:
    ///   - title: 알림 제목
    ///   - content: 알림 내용
    /// - Returns: 결정된 알림 타입
    func execute(title: String, content: String) -> NoticeAlarmType {
        let text = "\(title) \(content)"
        
        if let mlResult = repository.classifyWithML(text: text) {
            return mlResult
        }
        
        return repository.classifyWithKeywords(text: text)
    }
}
