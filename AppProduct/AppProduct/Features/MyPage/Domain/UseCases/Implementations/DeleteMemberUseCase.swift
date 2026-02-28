//
//  DeleteMemberUseCase.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

final class DeleteMemberUseCase: DeleteMemberUseCaseProtocol {
    private let repository: MyPageRepositoryProtocol

    init(repository: MyPageRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws {
        try await repository.deleteMember()
    }
}
