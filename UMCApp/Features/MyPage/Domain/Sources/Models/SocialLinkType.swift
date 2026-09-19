//
//  SocialLinkType.swift
//  MyPageDomain
//
//  Created by euijjang97 on 5/10/26.
//

import Foundation

/// 외부 프로필 링크의 종류를 정의하는 열거형입니다.
///
/// UI 프로퍼티(icon/title/placeholder)는 Presentation 모듈의 extension으로 제공합니다.
public enum SocialLinkType: String, CaseIterable {
    /// 깃허브 링크
    case github = "GITHUB"
    /// 링크드인 링크
    case linkedin = "LINKEDIN"
    /// 개인 블로그 링크
    case blog = "BLOG"
    /// 인스타그램 링크
    case instagram = "INSTAGRAM"
    /// 개인 웹사이트·포트폴리오 링크
    case personal = "PERSONAL"

    /// API 요청/응답에서 사용하는 type 문자열
    public var apiType: String {
        switch self {
        case .github:    return "GITHUB"
        case .linkedin:  return "LINKEDIN"
        case .blog:      return "BLOG"
        case .instagram: return "INSTAGRAM"
        case .personal:  return "PERSONAL"
        }
    }

    /// API 문자열에서 SocialLinkType을 유추합니다.
    public init?(apiType: String) {
        switch apiType.uppercased() {
        case "GITHUB":    self = .github
        case "LINKEDIN":  self = .linkedin
        case "BLOG":      self = .blog
        case "INSTAGRAM": self = .instagram
        case "PERSONAL":  self = .personal
        default:          return nil
        }
    }
}
