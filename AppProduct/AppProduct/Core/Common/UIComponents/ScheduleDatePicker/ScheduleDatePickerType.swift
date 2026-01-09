//
//  ScheduleDatePickerType.swift
//  AppProduct
//
//  Created by 김미주 on 1/10/26.
//

import SwiftUI

enum ScheduleDatePickerType {
    case start
    case end

    var title: String {
        switch self {
        case .start: "시작"
        case .end: "종료"
        }
    }

    var tintColor: Color {
        switch self {
        case .start: .blue
        case .end: .gray
        }
    }
}
