//
//  MyCardVisibilityResponseDTO.swift
//  BusinessCardData
//
//  Created by euijjang97 on 11/19/26.
//

import Foundation
import UMCFoundation

/// 명함 수정 화면 응답 중 공개 여부만 (`GET /api/v1/member/me/business-card/edit`, MEMBER-105).
///
/// 이메일·링크 값은 정본 프로필(`/member/me`)로 그리고, 여기서는 무엇을 보일지만 읽는다 (#1678).
/// 응답에는 이름·사진·링크 값도 함께 오지만 쓰지 않는다.
public struct MyCardVisibilityResponseDTO: Codable, Equatable, Sendable {

    // MARK: - Property

    public let contact: ContactDTO?
    /// 링크 타입마다 하나씩 늘 5개 온다.
    public let links: [LinkDTO]

    // MARK: - Init

    public init(contact: ContactDTO?, links: [LinkDTO]) {
        self.contact = contact
        self.links = links
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case contact, links
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        contact = try container.decodeIfPresent(ContactDTO.self, forKey: .contact)
        links = try container.decodeIfPresent([LinkDTO].self, forKey: .links) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(contact, forKey: .contact)
        try container.encode(links, forKey: .links)
    }
}

// MARK: - Contact

extension MyCardVisibilityResponseDTO {

    /// 이메일 공개 여부. 값이 없으면 숨긴다 — 남에게 보이는 명함이라 모르면 가리는 쪽이 맞다.
    public struct ContactDTO: Codable, Equatable, Sendable {
        public let isPublic: Bool

        public init(isPublic: Bool) {
            self.isPublic = isPublic
        }

        private enum CodingKeys: String, CodingKey {
            case isPublic
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            isPublic = try container.decodeBoolFlexibleIfPresent(forKey: .isPublic) ?? false
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(isPublic, forKey: .isPublic)
        }
    }
}

// MARK: - Link

extension MyCardVisibilityResponseDTO {

    /// 외부 링크 하나의 공개 여부.
    public struct LinkDTO: Codable, Equatable, Sendable {
        /// 서버 `MemberProfileLinkType` 원문 (`GITHUB`·`LINKEDIN`·`INSTAGRAM`·`BLOG`·`PERSONAL`).
        public let type: String
        public let isPublic: Bool

        public init(type: String, isPublic: Bool) {
            self.type = type
            self.isPublic = isPublic
        }

        private enum CodingKeys: String, CodingKey {
            case type, isPublic
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = container.decodeFlexibleStringOrEmpty(forKey: .type)
            isPublic = try container.decodeBoolFlexibleIfPresent(forKey: .isPublic) ?? false
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)
            try container.encode(isPublic, forKey: .isPublic)
        }
    }
}
