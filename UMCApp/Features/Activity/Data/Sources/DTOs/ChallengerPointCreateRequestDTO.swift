//
//  ChallengerPointCreateRequestDTO.swift
//  ActivityData
//
//  Created by jaewon Lee on 6/28/26.
//

import Foundation
import UMCFoundation

/// 챌린저 포인트 부여 요청 DTO
///
/// `POST /api/v1/challenger/{challengerId}/points`
///
/// - Note: Request(Encodable) DTO 이므로 배점(`pointValue`)은 정수 그대로 직렬화합니다.
///   핵심 규칙 #2(서버 응답 정수 String 통일)는 식별자에 적용되며, 배점은 식별자가 아닙니다.
///   `pointType` 은 서버 문자열 rawValue 로 직렬화됩니다(``UMCFoundation/ChallengerPointType``).
struct ChallengerPointCreateRequestDTO: Encodable, Sendable, Equatable {

    // MARK: - Property

    /// 포인트 유형
    let pointType: ChallengerPointType

    /// CUSTOM의 정수 배점. 고정 유형은 생략하여 서버 기본 배점을 적용합니다.
    let pointValue: Int?

    /// 부여 사유
    let description: String

    // MARK: - Init

    init(pointType: ChallengerPointType, pointValue: Int, description: String) {
        self.pointType = pointType
        // 고정 유형은 서버 기본 배점을 사용합니다. 레거시 -0.5도 손실 없이 처리됩니다.
        self.pointValue = pointType.isCustom ? pointValue : nil
        self.description = description
    }
}
