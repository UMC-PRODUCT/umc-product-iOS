//
//  TermsDTO.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/10/26.
//

import Foundation

/// 약관 조회 API 응답 DTO
struct TermsDTO: Codable {

    // MARK: - Property

    /// 약관 ID (termsId로 사용, 서버 응답 문자열)
    let id: String
    /// 약관 링크
    let link: String
    /// 필수 동의 여부
    let isMandatory: Bool

    // MARK: - Mapping

    /// Domain 모델로 변환
    func toDomain(termsType: TermsType) -> Terms {
        Terms(
            id: id,
            link: link,
            isMandatory: isMandatory,
            termsType: termsType
        )
    }
}
