//
//  CardLinkType.swift
//  BusinessCardDomain
//
//  Created by euijjang97 on 11/19/26.
//

import Foundation

/// 명함 뒷면에 싣는 외부 링크 종류 (#1679).
///
/// 원시값은 서버 링크 타입 문자열이다. 마이페이지의 `SocialLinkType` 과 같은 값이지만
/// 명함 모듈은 마이페이지를 참조하지 않으므로 따로 둔다. 선언 순서가 기본 우선순위다.
public enum CardLinkType: String, CaseIterable, Hashable, Sendable {
    case github = "GITHUB"
    case linkedIn = "LINKEDIN"
    case blog = "BLOG"
    case instagram = "INSTAGRAM"
    case personal = "PERSONAL"

    /// 저장된 우선순위를 다섯 종류가 한 번씩 든 순서로 맞춘다.
    ///
    /// 중복은 앞의 것만 남기고, 빠진 종류는 기본 순서대로 뒤에 붙인다. 링크 종류가 늘어도
    /// 예전에 저장한 순서가 그대로 살아 있게 하려는 것이다.
    public static func normalizedPriority(_ priority: [CardLinkType]) -> [CardLinkType] {
        var seen = Set<CardLinkType>()
        let stored = priority.filter { seen.insert($0).inserted }
        return stored + allCases.filter { !seen.contains($0) }
    }
}
