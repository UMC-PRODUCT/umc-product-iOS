//
//  UpdateMyPageProfileImageUseCase.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

final class UpdateMyPageProfileImageUseCase: UpdateMyPageProfileImageUseCaseProtocol {
    private let repository: MyPageRepositoryProtocol

    init(repository: MyPageRepositoryProtocol) {
        self.repository = repository
    }

    func execute(
        imageData: Data,
        fileName: String,
        contentType: String
    ) async throws -> ProfileData {
        try await repository.updateProfileImage(
            imageData: imageData,
            fileName: fileName,
            contentType: contentType
        )
    }
}
