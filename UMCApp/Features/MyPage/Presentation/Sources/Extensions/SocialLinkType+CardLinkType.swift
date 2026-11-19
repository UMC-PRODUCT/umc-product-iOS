//
//  SocialLinkType+CardLinkType.swift
//  MyPagePresentation
//
//  Created by euijjang97 on 11/19/26.
//

import BusinessCardDomain
import MyPageDomain

/// 마이페이지 링크 종류와 명함 링크 종류는 같은 서버 링크 타입 문자열을 쓴다 (#1679).
extension SocialLinkType {

    init?(cardLinkType: CardLinkType) {
        self.init(apiType: cardLinkType.rawValue)
    }

    var cardLinkType: CardLinkType? {
        CardLinkType(rawValue: apiType)
    }
}
