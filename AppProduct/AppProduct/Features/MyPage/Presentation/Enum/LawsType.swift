//
//  LawsType.swift
//  AppProduct
//
//  Created by euijjang97 on 1/28/26.
//

import Foundation
import SwiftUI

/// MyPage에서 표시되는 법률 관련 문서 타입
///
/// 개인정보처리 방침, 이용약관 등의 법적 문서를 구분하고 각각의 아이콘 및 색상을 정의합니다.
enum LawsType: String, CaseIterable {
    /// 개인정보처리 방침
    case policy = "개인정보처리 방침"
    /// 이용약관
    case terms = "이용약관"

    /// 각 법률 문서 타입에 맞는 SF Symbol 아이콘 이름
    var icon: String {
        switch self {
        case .policy:
            return "hand.raised.fill"
        case .terms:
            return "doc.text.fill"
        }
    }

    /// 각 법률 문서 타입에 맞는 테마 색상
    var color: Color {
        switch self {
        case .policy:
            return .purple
        case .terms:
            return .green
        }
    }
}
