//
//  ScocialLinkType.swift
//  AppProduct
//
//  Created by euijjang97 on 1/26/26.
//

import Foundation
import SwiftUI

/// 외부 프로필 링크의 종류를 정의하는 열거형입니다.
enum SocialLinkType: String, CaseIterable {
    /// 깃허브 링크
    case github = "Github"
    /// 링크드인 링크
    case linkedin = "Linked in"
    /// 개인 블로그 링크
    case blog = "Blog"
    
    /// 각 링크 타입에 맞는 아이콘 아이콘(ImageResource)을 반환합니다.
    var icon: ImageResource {
        switch self {
        case .github:
            return .github
        case .linkedin:
            return .linkedIn
        case .blog:
            return .global
        }
    }
    
    /// 링크 입력 폼 등에서 사용될 필드 제목을 반환합니다.
    var title: String {
        switch self {
        case .github:
            return "Github URL"
        case .linkedin:
            return "LinkedIn URL"
        case .blog:
            return "Blog URL"
        }
    }
    
    /// 텍스트 필드 플레이스홀더로 보여줄 예시 URL을 반환합니다.
    var placeholder: String {
        switch self {
        case .github: return "https://github.com/"
        case .linkedin: return "https://linkedin.com/in/yourprofile"
        case .blog: return "https://yourblog.com"
        }
    }
}
