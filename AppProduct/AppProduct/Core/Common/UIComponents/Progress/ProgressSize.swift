//
//  ProgressSize.swift
//  AppProduct
//
//  Created by 이예지 on 1/23/26.
//

import Foundation
import SwiftUI

enum ProgressSize {
    case small
    case regular
    case large

    var controlSize: ControlSize {
        switch self {
        case .small:
            return .small
        case .regular:
            return .regular
        case .large:
            return .large
        }
    }
    
    var messageSize: AppFont {
        switch self {
        case .small:
            return .caption1
        case .regular:
            return .subheadline
        case .large:
            return .body
        }
    }
}
