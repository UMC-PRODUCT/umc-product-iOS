//
//  ProhibitedTextValidator.swift
//  UMCFoundation
//
//  Created by euijjang97 on 10/29/26.
//

import Foundation

/// 공개 입력의 전송 전 검증. 신고·문의, URL·이메일·비밀번호에는 호출하지 않는다.
///
/// NFKC·소문자·보이지 않는 포맷 문자 정규화와 수평 공백 삽입을 검사한다.
/// 문장 경계를 합치지 않도록 개행·구두점은 건너뛰지 않는다. 문맥·인용 의도는 판별하지
/// 않으며 서버 검증을 대체하지 않는다. 원문을 수정하거나 로그에 남기지 않는다.
public enum ProhibitedTextValidator {

    // MARK: - Property

    public static let userMessage = "사용할 수 없는 표현이 포함되어 있어요. 내용을 수정해 주세요."

    /// 정규식은 정적 목록에서 한 번만 만들고 모든 검사에서 재사용한다.
    private static let patterns = ProhibitedTextCatalog.entries.map { entry in
        let body = entry.text.map { NSRegularExpression.escapedPattern(for: String($0)) }
            .joined(separator: #"[\p{Zs}\t]*"#)
        // ‘아니거든’, ‘3개년 계획’ 같은 정상 단어 내부의 짧은 표현은 제외한다.
        // 따라서 이 두 표현 앞에 다른 글자를 붙인 합성 욕설 일부는 검출되지 않을 수 있다.
        let prefix = ["H014", "A011"].contains(entry.id) ? #"(?<![\p{L}\p{N}])"# : ""
        // 패턴 본문은 전부 escape된 정적 문자이고 나머지는 위 고정 문법이다.
        return try! NSRegularExpression(pattern: prefix + body)
    }

    // MARK: - Function

    /// 주어진 필드에 금지 표현이 있으면 기존 검증 에러로 전달한다.
    public static func validate(_ text: String, field: String) throws {
        guard containsProhibitedText(text) else { return }
        throw AppError.validation(.invalidValue(field: field, reason: userMessage))
    }

    public static func containsProhibitedText(_ text: String) -> Bool {
        let normalized = normalized(text)
        let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
        return patterns.contains { $0.firstMatch(in: normalized, range: range) != nil }
    }

    private static func normalized(_ text: String) -> String {
        let compatible = text.precomposedStringWithCompatibilityMapping.lowercased()
        let scalars = compatible.unicodeScalars.filter {
            !$0.properties.isDefaultIgnorableCodePoint
        }
        return String(String.UnicodeScalarView(scalars)).precomposedStringWithCanonicalMapping
    }
}
