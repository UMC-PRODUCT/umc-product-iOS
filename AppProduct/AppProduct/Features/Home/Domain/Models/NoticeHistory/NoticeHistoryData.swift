//
//  NoticeHistoryData.swift
//  AppProduct
//
//  Created by euijjang97 on 1/20/26.
//

import Foundation
import SwiftData

/// 알림 히스토리 모델
/// 알림 히스토리 데이터 모델 (SwiftData)
///
/// 사용자의 알림 내역을 로컬 데이터베이스에 저장하고 관리합니다.
/// `NoticeAlarmType`을 포함하여 알림의 성격(정보, 경고 등)을 구분합니다.
@Model
class NoticeHistoryData {
    /// 알림 고유 식별자
    var id: UUID = UUID()
    
    /// 알림 제목
    var title: String = ""
    
    /// 알림 내용
    var content: String = ""
    
    /// 알림 아이콘/타입 rawValue 저장값
    var iconRaw: String = NoticeAlarmType.info.rawValue
    
    /// 알림 생성 시간
    var createdAt: Date = Date()

    /// 알림 아이콘/타입
    ///
    /// SwiftData 저장은 `iconRaw`(String)로 처리하고,
    /// 앱에서는 enum으로 안전하게 접근합니다.
    var icon: NoticeAlarmType {
        get { NoticeAlarmType(rawValue: iconRaw) ?? .info }
        set { iconRaw = newValue.rawValue }
    }

    // MARK: - Init
    
    /// NoticeHistoryData 생성자
    /// - Parameters:
    ///   - id: 고유 식별자
    ///   - title: 알림 제목
    ///   - content: 알림 내용
    ///   - icon: 알림 아이콘 타입
    ///   - createdAt: 생성 시간
    init(
        id: UUID = .init(),
        title: String,
        content: String,
        icon: NoticeAlarmType,
        createdAt: Date
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.iconRaw = icon.rawValue
        self.createdAt = createdAt
    }

    // MARK: - CoreML Init
    
    /// CoreML을 이용한 스마트 생성자
    ///
    /// 제목과 내용을 기반으로 `NoticeClassifierUseCase`를 통해 알림 타입(icon)을 자동으로 분류하여 생성합니다.
    ///
    /// - Parameters:
    ///   - id: 고유 식별자
    ///   - title: 알림 제목
    ///   - content: 알림 내용
    ///   - createdAt: 생성 시간
    convenience init(
        id: UUID = .init(),
        title: String,
        content: String,
        createdAt: Date
    ) {
        let repository = NoticeClassifierRepositoryImpl()
        let usecase = NoticeClassifierUseCaseImpl(repository: repository)
        let classifiedIcon = usecase.execute(title: title, content: content)

        self.init(
            id: id,
            title: title,
            content: content,
            icon: classifiedIcon,
            createdAt: createdAt
        )
    }
}
