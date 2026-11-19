//
//  InvalidateMyCardCacheUseCase.swift
//  BusinessCardDomain
//
//  Created by euijjang97 on 11/19/26.
//

import Foundation

public final class InvalidateMyCardCacheUseCase:
    InvalidateMyCardCacheUseCaseProtocol, @unchecked Sendable {

    // MARK: - Property

    private let repository: BusinessCardRepositoryProtocol

    // MARK: - Init

    public init(repository: BusinessCardRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    public func execute() async {
        await repository.invalidateMyCardCache()
    }
}
