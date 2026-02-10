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

    /// 약관 ID (termsId로 사용)
    let id: Int
    /// 약관 제목
    let title: String
    /// 약관 내용 (HTML)
    let content: String
    /// 필수 동의 여부
    let isMandatory: Bool

    // MARK: - Mapping

    /// Domain 모델로 변환
    func toDomain(termsType: TermsType) -> Terms {
        Terms(
            id: id,
            title: title,
            content: content,
            isMandatory: isMandatory,
            termsType: termsType
        )
    }
}
