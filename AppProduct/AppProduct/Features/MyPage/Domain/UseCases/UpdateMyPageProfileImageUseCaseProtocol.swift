//
//  UpdateMyPageProfileImageUseCaseProtocol.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

protocol UpdateMyPageProfileImageUseCaseProtocol {
    func execute(
        imageData: Data,
        fileName: String,
        contentType: String
    ) async throws -> ProfileData
}
