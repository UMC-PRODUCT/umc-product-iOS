//
//  ThreadMemberProfileUseCase.swift
//  CommunityDomain
//
//  Created by euijjang97 on 11/19/26.
//

import Foundation

/// 스레드에서 메시지 발신자·참여자를 눌렀을 때 보이는 프로필 조회 (#1681).
public protocol ThreadMemberProfileUseCaseProtocol: Sendable {
    func loadProfile(memberId: String) async throws -> ThreadMemberProfile
}

public struct ThreadMemberProfileUseCase: ThreadMemberProfileUseCaseProtocol {

    // MARK: - Property

    private let repository: ThreadMemberProfileRepositoryProtocol

    // MARK: - Init

    public init(repository: ThreadMemberProfileRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    public func loadProfile(memberId: String) async throws -> ThreadMemberProfile {
        ThreadMemberProfile(profile: try await repository.fetchProfile(memberId: memberId))
    }
}
