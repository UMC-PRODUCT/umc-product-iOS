//
//  String+ServerErrorMessage.swift
//  MyPagePresentation
//
//  Created by euijjang97 on 9/14/26.
//

import Foundation

extension String {
    /// 사용자에게 노출할 문구에서 `CHALLENGER-0012:` 같은 서버 코드 접두사를 걷어낸다.
    func strippingServerErrorCode() -> String {
        let trimmed = self
            .replacingOccurrences(
                of: #"^[A-Z]+-\d{4}\s*[:\-]?\s*"#,
                with: "",
                options: .regularExpression
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return trimmed.isEmpty ? "인증에 실패했습니다. 다시 시도해주세요." : trimmed
    }
}
