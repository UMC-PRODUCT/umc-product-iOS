//
//  SeasonCard.swift
//  AppProduct
//
//  Created by euijjang97 on 1/13/26.
//

import SwiftUI

/// 홈 화면 상단의 기수 및 활동일 정보를 표현하는 타입
///
/// 사용자의 누적 활동일과 참여 기수 정보를 표시하는 데 사용됩니다.
enum SeasonType: Equatable {
    /// 누적 활동일 (일수)
    case days(Int)
    /// 참여 기수 목록 (기수 배열)
    case gens([Int])
    
    
    /// 카드에 표시될 아이콘 이미지
    var image: Image? {
        switch self {
        case .days:
            return Image(systemName: "medal.star.fill")
        case .gens:
            return nil
        }
    }
    
    /// 카드 타이틀 텍스트
    var text: String {
        switch self {
        case .days:
            return "누적 활동일"
        case .gens:
            return "참여 기수"
        }
    }
    
    /// 총 활동일 수 또는 참여 기수 개수
    var value: Int {
        switch self {
        case .days(let day):
            return day
        case .gens(let gens):
            return gens.count
        }
    }
    
    /// 참여 기수 목록 (참여 기수 타입일 경우 반환)
    var gens: [Int]? {
        switch self {
        case .days:
            return nil
        case .gens(let gens):
            return gens
        }
    }
    
    /// 타이틀 텍스트 색상
    var fontColor: Color {
        switch self {
        case .days:
            return .indigo600
        case .gens:
            return .yellow500
        }
    }
    
    /// 값 텍스트 색상
    var valueColor: Color {
        switch self {
        case .days:
            return .grey000
        case .gens:
            return .grey900
        }
    }
    
    /// 값에 붙는 단위 태그 (Days, Gen)
    var valueTag: String {
        switch self {
        case .days:
            return "Days"
        case .gens:
            return "Gen"
        }
    }
}
