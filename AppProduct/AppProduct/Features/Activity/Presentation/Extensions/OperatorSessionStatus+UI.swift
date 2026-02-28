//
//  OperatorSessionStatus+UI.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/6/26.
//

import SwiftUI

/// OperatorSessionStatus의 UI 관련 확장
///
/// Domain에서 SwiftUI 의존성을 제거하고 Presentation 계층에서 UI 프로퍼티를 제공합니다.
extension OperatorSessionStatus {

    /// 상태 아이콘 색상
    var iconColor: Color {
        switch self {
        case .beforeStart: return .gray.opacity(0.7)
        case .inProgress: return .indigo400
        case .ended: return .green.opacity(0.7)
        }
    }

    /// 상태 텍스트 색상
    var textColor: Color {
        switch self {
        case .beforeStart: return .grey600
        case .inProgress: return .indigo500
        case .ended: return .gray
        }
    }
}
