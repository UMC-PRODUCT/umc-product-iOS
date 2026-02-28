//
//  Terms.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/10/26.
//

import Foundation

/// 약관 도메인 모델
struct Terms: Equatable, Identifiable {

    // MARK: - Property

    /// 약관 ID (서버 id 필드, 문자열)
    let id: String
    /// 약관 링크
    let link: String
    /// 필수 동의 여부
    let isMandatory: Bool
    /// 약관 종류
    let termsType: TermsType
}

/// 약관 종류
enum TermsType: String, CaseIterable {
    /// 서비스 이용약관
    case service = "SERVICE"
    /// 개인정보 처리방침
    case privacy = "PRIVACY"
    /// 마케팅 정보 수신 동의
    case marketing = "MARKETING"
}
