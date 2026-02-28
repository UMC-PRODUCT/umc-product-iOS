//
//  NoticeClassifierUseCase.swift
//  AppProduct
//
//  Created by euijjang97 on 1/21/26.
//

import Foundation

/// 알림 분류 유스케이스 프로토콜
///
/// 알림의 제목과 내용을 기반으로 최적의 알림 카테고리(아이콘)를 결정하는 비즈니스 로직을 수행합니다.
protocol NoticeClassifierUseCase {
    
    /// 알림 분류를 실행합니다.
    /// - Parameters:
    ///   - title: 알림 제목
    ///   - content: 알림 내용
    /// - Returns: 결정된 알림 타입 (`NoticeAlarmType`)
    func execute(title: String, content: String) -> NoticeAlarmType
}
