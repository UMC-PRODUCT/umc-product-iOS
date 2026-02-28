//
//  NoticeType.swift
//  AppProduct
//
//  Created by euijjang97 on 1/20/26.
//

import Foundation
import SwiftUI

/// 알림 상태 타입 (성공, 정보, 경고, 에러)
///
/// 각종 알림 뷰나 토스트 메시지 등에서 상태에 따른 UI 처리를 위해 사용됩니다.
enum NoticeAlarmType: String, Codable {
    /// 성공 상태 (초록색, 체크마크)
    case success
    /// 정보 상태 (파란색, 정보 아이콘)
    case info
    /// 경고 상태 (노란색, 느낌표)
    case warning
    /// 에러 상태 (빨간색, X마크)
    case error
    
    /// 각 상태에 해당하는 시스템 이미지 이름
    var image: String {
        switch self {
        case .success:
            return "checkmark.circle"
        case .info:
            return "info.circle"
        case .warning:
            return "exclamationmark.circle"
        case .error:
            return "xmark.circle"
        }
    }
    
    /// 각 상태에 해당하는 색상
    var color: Color {
        switch self {
        case .success:
            return .green
        case .info:
            return .blue
        case .warning:
            return .yellow
        case .error:
            return .red
        }
    }
}
