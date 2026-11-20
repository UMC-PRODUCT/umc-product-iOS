//
//  BusinessCardContactDTO.swift
//  MyPageData
//
//  Created by euijjang97 on 11/19/26.
//

import Foundation
import MyPageDomain
import UMCFoundation

// MARK: - Response

/// 명함 수정 화면 응답 중 연락처·링크 (`GET /api/v1/member/me/business-card/edit`, MEMBER-105).
///
/// 저장 응답(MEMBER-006)도 같은 모양이다. 비공개 항목도 공개 여부와 함께 오고, 링크는
/// 입력하지 않은 종류까지 항상 5개가 온다(`link` 가 `null`). 이름·학교·연동 계정도 함께
/// 오지만 화면은 프로필 값을 쓰므로 읽지 않는다.
public struct BusinessCardEditResponseDTO: Codable, Equatable {

    // MARK: - Property

    public let contact: BusinessCardContactDTO?
    public let links: [BusinessCardLinkDTO]

    // MARK: - Init

    public init(contact: BusinessCardContactDTO?, links: [BusinessCardLinkDTO]) {
        self.contact = contact
        self.links = links
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case contact, links
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        contact = try container.decodeIfPresent(BusinessCardContactDTO.self, forKey: .contact)
        links = try container.decodeIfPresent([BusinessCardLinkDTO].self, forKey: .links) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(contact, forKey: .contact)
        try container.encode(links, forKey: .links)
    }
}

/// 연락 이메일. 로그인 이메일과 별개로 사용자가 따로 입력한 값이다.
public struct BusinessCardContactDTO: Codable, Equatable {
    public let email: String?
    public let isPublic: Bool

    public init(email: String?, isPublic: Bool) {
        self.email = email
        self.isPublic = isPublic
    }

    private enum CodingKeys: String, CodingKey {
        case email, isPublic
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        email = container.decodeFlexibleStringOrNil(forKey: .email)
        isPublic = try container.decodeBoolFlexibleIfPresent(forKey: .isPublic) ?? true
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encode(isPublic, forKey: .isPublic)
    }
}

/// 외부 링크 한 줄. `type` 은 서버 `MemberProfileLinkType` 원문이다.
public struct BusinessCardLinkDTO: Codable, Equatable {
    public let type: String
    public let link: String?
    public let isPublic: Bool

    public init(type: String, link: String?, isPublic: Bool) {
        self.type = type
        self.link = link
        self.isPublic = isPublic
    }

    private enum CodingKeys: String, CodingKey {
        case type, link, isPublic
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = container.decodeFlexibleStringOrEmpty(forKey: .type)
        link = container.decodeFlexibleStringOrNil(forKey: .link)
        isPublic = try container.decodeBoolFlexibleIfPresent(forKey: .isPublic) ?? true
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(link, forKey: .link)
        try container.encode(isPublic, forKey: .isPublic)
    }
}

// MARK: - Request

/// 명함 수정 요청 (`PATCH /api/v1/member/me/business-card`, MEMBER-006).
///
/// 서버는 링크를 **전체 교체**한다 — 목록에 없는 종류는 지운다. 그래서 링크 5종을 늘
/// 모두 보내고, 비운 링크는 `link` 를 빼서(`null`) 보낸다. 빈 문자열을 보내면 빈 값이
/// 그대로 저장된다. 프로필 사진(`profileImageId`)은 기존 사진 변경 경로가 따로 맡아 보내지
/// 않는다 — 생략하면 서버가 기존 사진을 유지한다.
public struct EditBusinessCardRequestDTO: Encodable, Equatable {
    public let contact: Contact
    public let links: [Link]

    public struct Contact: Encodable, Equatable {
        /// 비우면 서버가 연락처를 지운다.
        public let email: String?
        public let isPublic: Bool
    }

    public struct Link: Encodable, Equatable {
        public let type: String
        public let link: String?
        public let isPublic: Bool
    }

    public init(contact: Contact, links: [Link]) {
        self.contact = contact
        self.links = links
    }
}

// MARK: - Mapping

extension BusinessCardEditResponseDTO {

    /// 모르는 링크 종류는 버린다. 서버가 종류를 늘려도 화면이 다룰 수 없는 값이다.
    func toDomain() -> CardContactSettings {
        var links: [SocialLinkType: CardContactItem] = [:]
        for link in self.links {
            guard let type = SocialLinkType(apiType: link.type) else { continue }
            links[type] = CardContactItem(value: link.link ?? "", isPublic: link.isPublic)
        }
        return CardContactSettings(
            isEmailPublic: contact?.isPublic ?? CardContactItem.empty.isPublic,
            contactEmail: contact?.email,
            links: links
        )
    }
}

extension EditBusinessCardRequestDTO {

    init(settings: CardContactSettings) {
        let normalized = settings.normalized
        self.init(
            // 화면에 보이는 이메일은 계정 이메일이고 여기서는 공개 여부만 바꾼다. 연락용 이메일은
            // 받은 그대로 돌려보낸다 — 비워 보내면 서버가 저장된 값을 지운다.
            contact: Contact(email: normalized.contactEmail, isPublic: normalized.isEmailPublic),
            links: SocialLinkType.allCases.map { type in
                let item = normalized.link(type)
                return Link(
                    type: type.apiType,
                    link: item.value.isEmpty ? nil : item.value,
                    isPublic: item.isPublic
                )
            }
        )
    }
}
