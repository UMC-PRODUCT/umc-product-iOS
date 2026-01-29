//
//  String.swift
//  AppProduct
//
//  Created by 김미주 on 1/28/26.
//

import Foundation

extension String {

    /// 글자 단위 줄바꿈
    var forceCharWrapping: Self {
        self.map({ String($0) }).joined(separator: "\u{200B}")
    }

    /// HTTP/HTTPS URL 유효성 검사
    var isValidHTTPURL: Bool {
        guard let url = URL(string: self),
              let scheme = url.scheme,
              ["http", "https"].contains(scheme.lowercased()),
              url.host != nil else {
            return false
        }
        return true
    }
}
