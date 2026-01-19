//
//  PenalyInfoType.swift
//  AppProduct
//
//  Created by euijjang97 on 1/14/26.
//

import SwiftUI

/// 패널티 정보 아이템
struct PenaltyInfoItem: Equatable {
    let reason: String
    let date: String
    let penaltyPoint: Int
}

enum InfoType {
    case penalties(Int)
    case infoText([PenaltyInfoItem])

    var text: String {
        switch self {
        case .penalties:
            return "패널티"
        case .infoText:
            return "패널티 기록"
        }
    }

    var point: Int? {
        switch self {
        case .penalties(let point):
            return  point
        case .infoText:
            return nil
        }
    }

    var infoItems: [PenaltyInfoItem]? {
        switch self {
        case .penalties:
            return nil
        case .infoText(let items):
            return items
        }
    }

    var fontColor: Color {
        switch self {
        case .penalties:
            return .grey600
        case .infoText:
            return .red
        }
    }
}
