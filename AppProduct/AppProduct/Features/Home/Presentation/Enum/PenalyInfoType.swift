//
//  PenalyInfoType.swift
//  AppProduct
//
//  Created by euijjang97 on 1/14/26.
//

import SwiftUI

/// 패널티 정보 아이템
struct PenaltyInfoItem: Equatable {
    /// 패널티 사유 (예: 지각, 결석 등)
    let reason: String
    /// 패널티 발생 날짜 (YYYY.MM.DD)
    let date: String
    /// 부과된 벌점
    let penaltyPoint: Int
}

/// 패널티 정보 표시 타입
///
/// 패널티 점수 요약 또는 상세 기록 표시에 사용됩니다.
enum InfoType {
    /// 패널티 총점 표시
    case penalties(Int)
    /// 패널티 상세 기록 리스트 표시
    case infoText([PenaltyInfoItem])

    /// 표시할 텍스트 타이틀
    var text: String {
        switch self {
        case .penalties:
            return "패널티"
        case .infoText:
            return "기록"
        }
    }

    /// 패널티 점수 (총점 타입일 경우 반환)
    var point: Int? {
        switch self {
        case .penalties(let point):
            return  point
        case .infoText:
            return nil
        }
    }

    /// 패널티 상세 기록 아이템 (기록 타입일 경우 반환)
    var infoItems: [PenaltyInfoItem]? {
        switch self {
        case .penalties:
            return nil
        case .infoText(let items):
            return items
        }
    }

    /// 폰트 색상
    var fontColor: Color {
        switch self {
        case .penalties:
            return .grey600
        case .infoText:
            return .grey600
        }
    }
}
