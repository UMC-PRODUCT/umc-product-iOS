//
//  MyPageTermsDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

struct MyPageTermsResponseDTO: Codable {
    let id: String
    let link: String
    let isMandatory: Bool

    func toDomain() -> MyPageTerms {
        MyPageTerms(
            id: id,
            link: link,
            isMandatory: isMandatory
        )
    }
}
