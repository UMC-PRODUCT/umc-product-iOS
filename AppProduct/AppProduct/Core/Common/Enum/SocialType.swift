//
//  SocialType.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import Foundation
import SwiftUI

/// 앱에서 지원하는 소셜 로그인 타입을 정의하는 열거형입니다.
enum SocialType: String, CaseIterable {
    /// 카카오 로그인
    case kakao = "Kakao"
    /// 애플 로그인
    case apple = "Apple"
    
    /// 소셜 타입에 해당하는 로고 이미지를 반환합니다.
    var image: Image {
        switch self {
        case .kakao:
            return Image(.kakao) // 카카오 로고 에셋
        case .apple:
            return Image(.apple) // 애플 로고 에셋
        }
    }
    
    /// 소셜 타입별 브랜드 컬러를 반환합니다.
    var color: Color {
        switch self {
        case .kakao:
            return Color.kakao // 카카오 고유 노란색
        case .apple:
            return Color.black // 애플 고유 검정색
        }
    }
    
    /// 소셜 버튼 위에 올라가는 텍스트/아이콘의 색상을 반환합니다.
    var fontColor: Color {
        switch self {
        case .kakao:
            return .black // 노란 배경엔 검은 글씨
        case .apple:
            return .white // 검은 배경엔 흰 글씨
        }
    }
}
