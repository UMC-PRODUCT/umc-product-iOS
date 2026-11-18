//
//  MyCard+CardFaceLabel.swift
//  BusinessCardPresentation
//
//  Created by euijjang97 on 8/31/26.
//

import BusinessCardDomain
import Foundation

/// 명함 면(面) 표기의 단일 진실 원천.
///
/// 표기 이름은 ``MyCard/nameWithNickname``(#1236) 한 곳에 있고 여기서는 그것을 읽기만 한다.
/// 뒷면 연락처·링크 줄(#1679)도 여기 모은다. 화면과 VoiceOver 가 같은 항목을 같은 순서로
/// 말해야 하므로, 파생 규칙이 뷰 안으로 흩어지면 둘이 서로 다른 값을 말하게 된다.
///
/// 접근성 라벨은 표기 이름과 달리 **면(面)이 있는 카드만** 여기 것을 쓴다.
/// 명함첩 셀·요약 카드는 뒤집히지 않아 「앞면.」 접두어가 붙으면 없는 뒷면을 암시한다.
extension MyCard {

    // MARK: - Contact

    /// 뒷면 연락처·링크 줄. 이메일 → GitHub → LinkedIn → Blog → Instagram → 개인링크 순이다.
    ///
    /// 값 없는 줄은 뺀다 — 빈 줄은 서버 미입력을 링크가 있는 것처럼 보이게 한다.
    /// 링크는 ``linkDisplayText(_:)`` 로 줄여 보이고, 누르면 여는 주소는 원래 값으로 만든다.
    var backFaceContacts: [CardContact] {
        let candidates: [(CardContact.Kind, String?)] = [
            (.email, email),
            (.github, github),
            (.linkedIn, linkedIn),
            (.blog, blog),
            (.instagram, instagram),
            (.personal, personal)
        ]
        return candidates.compactMap { kind, value in
            guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !value.isEmpty else { return nil }
            if kind == .email {
                let url = URL(string: Constants.mailScheme + value)
                return CardContact(kind: kind, value: value, url: url)
            }
            return CardContact(
                kind: kind,
                value: Self.linkDisplayText(value),
                url: Self.linkURL(value)
            )
        }
    }

    /// 링크는 입력 그대로(`https://www.github.com/umc/`) 오지만 카드 한 줄 폭이 좁아
    /// 사람이 읽는 부분만 남긴다. 스킴·`www.`·끝 `/` 는 어느 링크에나 붙어 폭만 차지하고,
    /// 남겨 두면 정작 아이디가 말줄임으로 잘린다.
    private static func linkDisplayText(_ url: String) -> String {
        var text = url
        for prefix in Constants.linkPrefixes where text.lowercased().hasPrefix(prefix) {
            text.removeFirst(prefix.count)
        }
        while text.hasSuffix("/") {
            text.removeLast()
        }
        return text.isEmpty ? url : text
    }

    /// 줄을 눌렀을 때 열 웹 주소. 스킴 없이 온 값(`github.com/umc`)은 `https://` 를 붙인다 —
    /// 그대로 두면 `URL` 이 상대 경로로 읽혀 열리지 않는다.
    ///
    /// `http(s)` 가 아닌 스킴은 열지 않는다. 받은 명함의 값은 상대가 넣은 것이라 다른 앱을
    /// 여는 주소가 섞여 올 수 있다.
    private static func linkURL(_ value: String) -> URL? {
        let lowercased = value.lowercased()
        let candidate: String
        if Constants.webSchemes.contains(where: lowercased.hasPrefix) {
            candidate = value
        } else if value.contains(Constants.schemeSeparator) {
            return nil
        } else {
            candidate = Constants.defaultWebScheme + value
        }
        guard let url = URL(string: candidate), url.host()?.isEmpty == false else { return nil }
        return url
    }

    // MARK: - Accessibility

    /// 「앞면. 홍길동/길동, iOS 파트, ○○대학교, 12기」.
    ///
    /// 접두어가 **지금 보이는 면**을 전달한다. 카드가 한 덩어리로 읽히는 탓에 면 정보가
    /// 라벨에 없으면 지금 어느 쪽을 보고 있는지 알 방법이 없다.
    ///
    /// 낭독 순서는 화면 순서를 그대로 따른다 — 이름 행 · 파트 행 다음에 발급 행을
    /// 학교(왼쪽) · 기수(오른쪽) 순으로 읽는다 (#1374).
    var frontFaceAccessibilityLabel: String {
        let items = [
            nameWithNickname,
            "\(partDisplayName)\(Constants.partSuffix)",
            university,
            "\(generation)\(Constants.generationSuffix)"
        ]
        return Constants.frontPrefix + items.joined(separator: Constants.separator)
    }

    /// 「뒷면. one@umc.dev, github.com/umc, …」. 줄이 없으면 빈 상태 문구를 읽는다.
    var backFaceAccessibilityLabel: String {
        let values = backFaceContacts.map(\.value)
        let items = values.isEmpty ? [CardFaceCopy.emptyContactsTitle] : values
        return Constants.backPrefix + items.joined(separator: Constants.separator)
    }
}

/// 명함 뒷면의 연락처·링크 한 줄.
struct CardContact: Hashable {
    enum Kind: Hashable {
        case email
        case github
        case linkedIn
        case blog
        case instagram
        case personal
    }

    let kind: Kind
    /// 카드에 보이는 값. 링크는 스킴·`www.`·끝 `/` 를 뗀 표기다.
    let value: String
    /// 줄을 누르면 여는 주소 — 이메일은 `mailto:`, 링크는 웹 주소. 열 수 없는 값이면 `nil` 이고
    /// 줄은 텍스트로만 둔다.
    let url: URL?

    /// VoiceOver 액션 이름. 뒷면이 한 덩어리로 읽혀 줄 버튼에 닿을 수 없어 액션으로 연다.
    var openActionName: String {
        switch kind {
        case .email: "메일 보내기"
        case .github: "GitHub 열기"
        case .linkedIn: "LinkedIn 열기"
        case .blog: "블로그 열기"
        case .instagram: "Instagram 열기"
        case .personal: "개인 링크 열기"
        }
    }
}

/// 화면과 VoiceOver 가 함께 쓰는 명함 문구.
enum CardFaceCopy {
    static let emptyContactsTitle = "등록된 연락처와 소개 링크가 없어요"
    static let emptyContactsHint = "프로필 정보 편집에서 정보를 추가해 명함을 완성해 보세요."
}

// MARK: - Constants

private enum Constants {
    static let frontPrefix = "앞면. "
    static let backPrefix = "뒷면. "
    static let separator = ", "
    static let partSuffix = " 파트"
    static let generationSuffix = "기"
    static let webSchemes = ["https://", "http://"]
    static let defaultWebScheme = "https://"
    static let schemeSeparator = "://"
    static let mailScheme = "mailto:"
    /// 앞에서부터 차례로 뗀다 — `https://www.` 처럼 겹쳐 붙은 경우도 둘 다 떨어진다.
    static let linkPrefixes = webSchemes + ["www."]
}
