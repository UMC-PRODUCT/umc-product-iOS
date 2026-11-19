//
//  CardContactSettingsUseCase.swift
//  MyPageDomain
//
//  Created by euijjang97 on 11/19/26.
//

import Foundation

/// 명함 연락처·링크 설정 조회 구현체
public final class FetchCardContactSettingsUseCase: FetchCardContactSettingsUseCaseProtocol {

    // MARK: - Property

    private let repository: CardContactSettingsRepositoryProtocol

    // MARK: - Function

    public init(repository: CardContactSettingsRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> CardContactSettings {
        try await repository.fetchCardContactSettings()
    }
}

/// 명함 연락처·링크 설정 저장 구현체
public final class UpdateCardContactSettingsUseCase: UpdateCardContactSettingsUseCaseProtocol {

    // MARK: - Property

    private let repository: CardContactSettingsRepositoryProtocol

    // MARK: - Function

    public init(repository: CardContactSettingsRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(_ settings: CardContactSettings) async throws -> CardContactSettings {
        try await repository.updateCardContactSettings(settings.normalized)
    }
}
