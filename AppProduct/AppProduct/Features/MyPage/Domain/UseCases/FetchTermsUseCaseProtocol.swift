//
//  FetchTermsUseCaseProtocol.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

protocol FetchTermsUseCaseProtocol {
    func execute(termsType: String) async throws -> MyPageTerms
}
