//
//  MyCardVisibilityResponseDTO+MyCard.swift
//  BusinessCardData
//
//  Created by euijjang97 on 11/19/26.
//

import Foundation
import BusinessCardDomain

extension MyCardVisibilityResponseDTO {

    /// 정본 프로필로 만든 명함에서 비공개로 둔 이메일·링크를 뺀다 (#1678).
    ///
    /// 정본 프로필(`/member/me`)은 공개 여부와 상관없이 값을 모두 주므로, 그대로 그리면 숨긴
    /// 값이 내 명함과 교환 페이로드에 남는다. 공개로 확인된 항목만 남기고, 응답에 없는 종류도
    /// 숨긴다. 앞면 값과 링크 우선순위는 손대지 않는다.
    func applyingVisibility(to card: MyCard) -> MyCard {
        let publicLinks = Set(
            links.filter(\.isPublic).compactMap { CardLinkType(rawValue: $0.type.uppercased()) }
        )
        func visible(_ type: CardLinkType) -> String? {
            publicLinks.contains(type) ? card.link(type) : nil
        }

        return MyCard(
            memberId: card.memberId,
            name: card.name,
            nickname: card.nickname,
            part: card.part,
            generation: card.generation,
            university: card.university,
            email: contact?.isPublic == true ? card.email : nil,
            github: visible(.github),
            linkedIn: visible(.linkedIn),
            blog: visible(.blog),
            instagram: visible(.instagram),
            personal: visible(.personal),
            avatarURL: card.avatarURL,
            partRaw: card.partRaw,
            linkPriority: card.linkPriority
        )
    }
}
