//
//  CardContactSettings.swift
//  MyPageDomain
//
//  Created by euijjang97 on 11/19/26.
//

import Foundation

/// 명함 링크와 항목별 공개 여부 (#1678).
///
/// 서버 명함 수정 API(MEMBER-105 조회 · MEMBER-006 저장)의 연락처·링크 묶음이다. 이메일은
/// 따로 입력받지 않고 계정에 있는 이메일을 쓰므로 공개 여부만 든다.
public struct CardContactSettings: Equatable, Hashable, Sendable {

    // MARK: - Property

    /// 명함 뒷면과 다른 회원에게 이메일을 보일지. 서버 기본값이 공개다.
    public var isEmailPublic: Bool
    /// 서버에 저장된 연락용 이메일. 화면에는 쓰지 않고 저장할 때 받은 그대로 돌려보낸다 —
    /// 저장 API가 이 칸을 늘 함께 받아서, 비워 보내면 저장된 값이 지워진다.
    public var contactEmail: String?
    /// 링크 5종. 비어 있는 종류는 ``link(_:)`` 가 빈 값으로 돌려준다.
    public var links: [SocialLinkType: CardContactItem]

    // MARK: - Init

    public init(
        isEmailPublic: Bool = true,
        contactEmail: String? = nil,
        links: [SocialLinkType: CardContactItem] = [:]
    ) {
        self.isEmailPublic = isEmailPublic
        self.contactEmail = contactEmail
        self.links = links
    }

    // MARK: - Function

    public func link(_ type: SocialLinkType) -> CardContactItem {
        links[type] ?? .empty
    }

    /// 값 앞뒤 공백을 떼고 링크 5종을 모두 채운 형태. 변경 감지와 저장 요청이 같은 값을 본다.
    public var normalized: CardContactSettings {
        CardContactSettings(
            isEmailPublic: isEmailPublic,
            contactEmail: contactEmail,
            links: Dictionary(
                uniqueKeysWithValues: SocialLinkType.allCases.map { ($0, link($0).trimmed) }
            )
        )
    }

    /// `saved` 와 비교해 **바뀐** 링크 중 형식이 틀린 첫 링크. 모두 맞으면 `nil`.
    ///
    /// 바뀐 값만 본다. 예전 API로 스킴 없이 저장한 링크가 남아 있어도, 손대지 않았다면
    /// 다른 항목 저장까지 막지 않는다(Android와 같은 기준).
    public func firstInvalidLink(comparedTo saved: CardContactSettings) -> SocialLinkType? {
        let current = normalized
        let previous = saved.normalized
        return SocialLinkType.allCases.first { type in
            let value = current.link(type).value
            return value != previous.link(type).value
                && !value.isEmpty
                && !Self.isOpenableLink(value)
        }
    }

    // MARK: - Private Function

    /// 서버가 명함에 싣는 기준(`LinkTypeAndLink.isOpenable`)과 같다 — http(s) 스킴에 점이 든
    /// 호스트가 있어야 한다. 이 기준을 벗어나면 저장은 돼도 명함에는 나오지 않는다.
    private static func isOpenableLink(_ value: String) -> Bool {
        guard let components = URLComponents(string: value),
              let scheme = components.scheme?.lowercased(),
              Constants.openableSchemes.contains(scheme),
              let host = components.host else { return false }
        return host.contains(".")
    }
}

/// 링크 한 항목.
public struct CardContactItem: Equatable, Hashable, Sendable {

    // MARK: - Property

    public var value: String
    public var isPublic: Bool

    /// 입력하지 않은 항목. 서버 기본값이 공개라 공개로 둔다.
    public static let empty = CardContactItem(value: "", isPublic: true)

    var trimmed: CardContactItem {
        CardContactItem(
            value: value.trimmingCharacters(in: .whitespacesAndNewlines),
            isPublic: isPublic
        )
    }

    // MARK: - Init

    public init(value: String, isPublic: Bool) {
        self.value = value
        self.isPublic = isPublic
    }
}

// MARK: - Constants

private enum Constants {
    static let openableSchemes: Set<String> = ["http", "https"]
}
