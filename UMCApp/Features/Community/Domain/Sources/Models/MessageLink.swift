//
//  MessageLink.swift
//  CommunityDomain
//
//  Created by euijjang97 on 8/13/26.
//

import Foundation

/// 앱 안의 화면을 가리키는 내부 링크.
///
/// 메시지 본문에서 뽑아 카드로 그리고(#1142), 공유 시트가 복사해 나가는 값(#1138)이 같은
/// 타입이어야 "공유한 링크를 붙여 넣으면 카드가 뜬다" 가 성립한다. 그래서 생성(``urlString``)과
/// 해석(``parse(_:)-4l5ny``)을 한 타입에 모아 두고 양쪽 피처가 함께 쓴다.
///
/// - Note: 외부 URL 은 여기 들어오지 않는다. 카드로 그리는 대상은 내부 링크뿐이고,
///   그 밖의 URL 은 일반 텍스트 링크로 남긴다 (명세 FLOW 04).
public enum MessageLink: Hashable, Sendable {

    // MARK: - Cases

    case notice(id: String)
    case thread(id: String)

    // MARK: - Constants

    /// 커스텀 스킴. `Info.plist` 의 `CFBundleURLTypes` 에 등록된 값과 같아야 한다.
    public static let scheme = "umc"
    /// 과거 공유 링크를 계속 열기 위한 웹 호스트.
    public static let shareHost = "umc.it.kr"
    /// 과거 웹 공유 링크의 스레드 경로 접두사 (`https://umc.it.kr/t/12`).
    public static let shareThreadPath = "t"

    /// 서버 Universal Link 계약의 운영·개발 호스트.
    private static let threadShareHosts: Set<String> = [
        "api.university.neordinary.com", "dev.api.university.neordinary.com",
        "api-dev.university.neordinary.com",
    ]

    // MARK: - Computed Property

    public var id: String {
        switch self {
        case .notice(let id), .thread(let id):
            return id
        }
    }

    /// `umc://` 링크의 host 자리. 케이스 이름과 1:1이라 파싱과 생성이 같은 표를 본다.
    public var kind: String {
        switch self {
        case .notice:
            return "notice"
        case .thread:
            return "thread"
        }
    }

    /// 알림·내부 이동용 커스텀 링크 문자열 (`umc://thread/12`).
    /// 스레드 외부 공유에는 ``threadShareURL(id:serverURL:baseURL:)`` 을 사용한다.
    public var urlString: String {
        "\(Self.scheme)://\(kind)/\(id)"
    }

    /// ``urlString`` 을 URL 로 만든 값. `id` 가 URL 에 못 들어가는 문자를 담고 있으면 `nil`.
    public var url: URL? {
        URL(string: urlString)
    }

    // MARK: - Static Function

    /// 내부 링크 URL 을 해석한다. 내부 링크가 아니면 `nil`.
    ///
    /// 기존 커스텀 스킴·웹 링크와 HTTPS Universal Link를 받는다.
    /// - 커스텀 스킴 `umc://thread/12` · `umc://notice/34` — 앱 밖에서 들어오는 딥링크
    /// - HTTPS 공유 링크 `https://{api host}/community/threads/12` 및 Android query 표기
    /// - 과거 웹 공유 링크 `https://umc.it.kr/t/12`
    public static func parse(_ url: URL) -> MessageLink? {
        let segments = url.pathComponents.filter { $0 != "/" }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryIds = components?.queryItems?.filter { $0.name == "threadId" } ?? []

        if url.scheme?.lowercased() == scheme {
            let id = segments.count == 1 ? segments.first :
                (segments.isEmpty && queryIds.count == 1 ? queryIds.first?.value : nil)
            guard let id, isValidIdentifier(id) else { return nil }
            switch url.host?.lowercased() {
            case "thread": return .thread(id: id)
            case "notice" where segments.count == 1: return .notice(id: id)
            default: return nil
            }
        }

        guard url.scheme?.lowercased() == "https",
              url.user == nil, url.password == nil,
              url.port == nil || url.port == 443 else { return nil }

        if let host = url.host?.lowercased(), threadShareHosts.contains(host) {
            guard segments.prefix(2) == ["community", "threads"] else { return nil }
            let id = segments.count == 3 ? segments.last :
                (segments.count == 2 && queryIds.count == 1 ? queryIds.first?.value : nil)
            guard let id, isValidIdentifier(id) else { return nil }
            return .thread(id: id)
        }

        // 과거 공유 링크도 계속 열 수 있도록 보존한다.
        guard url.host?.lowercased() == shareHost,
              segments.count == 2,
              segments[0] == shareThreadPath,
              isValidIdentifier(segments[1]) else { return nil }
        return .thread(id: segments[1])
    }

    /// 서버 공유 URL과 앱의 API 환경을 사용해 경로형 HTTPS 공유 링크를 만든다.
    /// 상대 API 경로·커스텀 스킴·다른 스레드 링크를 그대로 공유하지 않는다.
    public static func threadShareURL(
        id: String,
        serverURL: String?,
        baseURL: URL? = nil
    ) -> URL? {
        guard isValidIdentifier(id) else { return nil }
        var host = baseURL?.host?.lowercased() ?? "api.university.neordinary.com"
        guard threadShareHosts.contains(host) else { return nil }
        if let serverURL,
           let url = URL(string: serverURL.trimmingCharacters(in: .whitespacesAndNewlines)),
           parse(url) == .thread(id: id),
           let serverHost = url.host?.lowercased(), threadShareHosts.contains(serverHost) {
            host = serverHost
        }
        return URL(string: "https://\(host)/community/threads/\(id)")
    }

    public static func parse(_ string: String) -> MessageLink? {
        guard let url = URL(string: string.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
        }
        return parse(url)
    }

    /// 본문을 텍스트 조각과 내부 링크로 쪼갠다.
    ///
    /// 내부 링크가 하나도 없으면 원본 한 조각만 돌려주므로, 호출부는 결과 개수로 "카드가 붙는
    /// 메시지인지" 를 따로 판단하지 않아도 된다.
    public static func segments(in content: String) -> [MessageContentSegment] {
        guard let detector, !content.isEmpty else {
            return content.isEmpty ? [] : [.text(content)]
        }

        let full = NSRange(content.startIndex..., in: content)
        var segments: [MessageContentSegment] = []
        var cursor = content.startIndex

        for match in detector.matches(in: content, range: full) {
            guard let candidateRange = Range(match.range, in: content) else { continue }
            var raw = String(content[candidateRange])
            // 문장 끝 구두점은 URL에서 제외하되, 잘못된 ID 접미사는 통째로 검증한다.
            while let last = raw.last, ".,!?;:)]}\"'".contains(last) {
                raw.removeLast()
            }
            guard let link = parse(raw) else { continue }
            let end = content.index(candidateRange.lowerBound, offsetBy: raw.count)
            let range = candidateRange.lowerBound..<end

            if cursor < range.lowerBound {
                segments.append(.text(String(content[cursor..<range.lowerBound])))
            }
            segments.append(.link(link, raw: raw))
            cursor = range.upperBound
        }

        if cursor < content.endIndex {
            segments.append(.text(String(content[cursor...])))
        }
        return segments
    }

    // MARK: - Private

    /// 서버 식별자는 정수를 String 으로 직렬화한 값이다(핵심 규칙 #2). 숫자로 좁혀 두면 문장
    /// 부호가 링크 뒤에 붙어 있어도 식별자에 딸려 들어가지 않는다.
    private static func isValidIdentifier(_ value: String) -> Bool {
        !value.isEmpty && value.utf8.allSatisfy { (48...57).contains($0) }
    }

    /// 본문 스캐너. 패턴이 상수라 실패할 수 없지만, 실패하면 링크 없는 본문으로 취급한다.
    private static let detector = try? NSRegularExpression(
        pattern: #"(?:umc://(?:thread|notice)"#
            + #"|https://(?:umc\.it\.kr|(?:api(?:-dev)?|dev\.api)\.university\.neordinary\.com))"#
            + #"(?=[/?])[^\s<>]+"#,
        options: [.caseInsensitive]
    )
}

/// ``MessageLink/segments(in:)`` 이 돌려주는 본문 조각.
public enum MessageContentSegment: Hashable, Sendable {

    // MARK: - Cases

    case text(String)
    /// - Parameter raw: 본문에 적혀 있던 원문. 메타 조회가 실패했을 때 그대로 보여 준다.
    case link(MessageLink, raw: String)
}
