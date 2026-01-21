//
//  NoticeType.swift
//  AppProduct
//
//  Created by euijjang97 on 1/20/26.
//

import Foundation
import SwiftUI

enum NoticeAlarmType: String, Codable {
    case success
    case info
    case warning
    case error
    
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
