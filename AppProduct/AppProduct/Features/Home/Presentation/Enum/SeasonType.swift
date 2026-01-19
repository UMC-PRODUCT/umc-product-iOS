//
//  SeasonCard.swift
//  AppProduct
//
//  Created by euijjang97 on 1/13/26.
//

import SwiftUI

enum SeasonType: Equatable {
    case days(Int)
    case gens([Int])
    
    
    /// 카드 별 이미지
    var image: Image? {
        switch self {
        case .days:
            return Image(systemName: "medal.star.fill")
        case .gens:
            return nil
        }
    }
    
    /// 텍스트 표현
    var text: String {
        switch self {
        case .days:
            return "누적 활동일"
        case .gens:
            return "참여 기수"
        }
    }
    
    /// 총 활동일 및 누적 기수 총 갯수
    var value: Int {
        switch self {
        case .days(let day):
            return day
        case .gens(let gens):
            return gens.count
        }
    }
    
    /// 참여 기수 전체 반환
    var gens: [Int]? {
        switch self {
        case .days:
            return nil
        case .gens(let gens):
            return gens
        }
    }
    
    /// 타이틀 색상
    var fontColor: Color {
        switch self {
        case .days:
            return .indigo600
        case .gens:
            return .yellow500
        }
    }
    
    var valueColor: Color {
        switch self {
        case .days:
            return .grey000
        case .gens:
            return .grey900
        }
    }
    
    var valueTag: String {
        switch self {
        case .days:
            return "Days"
        case .gens:
            return "Gen"
        }
    }
}
