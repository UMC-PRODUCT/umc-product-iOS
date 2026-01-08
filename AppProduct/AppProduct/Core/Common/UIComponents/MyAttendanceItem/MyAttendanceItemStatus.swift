//
//  MyAttendanceItemStatus.swift
//  AppProduct
//
//  Created by 김미주 on 1/9/26.
//

import SwiftUI

enum MyAttendanceItemStatus {
    case present
    case late
    case absent

    var text: String {
        switch self {
        case .present:
            return "출석"
        case .late:
            return "지각"
        case .absent:
            return "결석"
        }
    }

    var color: Color {
        switch self {
        case .present:
            return .green
        case .late:
            return .yellow
        case .absent:
            return .red
        }
    }
}
