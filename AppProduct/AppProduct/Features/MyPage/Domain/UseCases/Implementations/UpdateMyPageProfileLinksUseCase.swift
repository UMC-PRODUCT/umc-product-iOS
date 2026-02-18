//
//  UpdateMyPageProfileLinksUseCase.swift
//  AppProduct
//
//  Created by euijjang97 on 2/18/26.
//

import Foundation

/// 프로필 외부 링크(GitHub, LinkedIn, Blog) 수정 UseCase 구현체
///
/// Repository를 통해 링크 수정 API를 호출하고 갱신된 프로필 데이터를 반환합니다.
final class UpdateMyPageProfileLinksUseCase: UpdateMyPageProfileLinksUseCaseProtocol {

    // MARK: - Property

    private let repository: MyPageRepositoryProtocol

    // MARK: - Init

    init(repository: MyPageRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    func execute(profileLinks: [ProfileLink]) async throws -> ProfileData {
        try await repository.updateProfileLinks(profileLinks)
    }
}
