//
//  ChangeEmailUseCaseTests.swift
//  AuthDomainTests
//
//  Created by euijjang97 on 9/19/26.
//

import CoreDomain
import Testing
@testable import AuthDomain

@Suite("ChangeEmailUseCase — Repository 위임 및 프로필 캐시 무효화 검증")
struct ChangeEmailUseCaseTests {

    @Test("변경에 성공하면 토큰을 그대로 전달하고 프로필 캐시를 무효화한다")
    func executeDelegatesAndInvalidatesCache() async throws {
        let repository = MockAuthRepository()
        let memberProfileRepository = SpyMemberProfileRepository()
        let useCase = ChangeEmailUseCase(
            repository: repository,
            memberProfileRepository: memberProfileRepository
        )

        try await useCase.execute(emailVerificationToken: "email-token")

        #expect(repository.changeEmailCallCount == 1)
        #expect(repository.changeEmailReceivedToken == "email-token")
        #expect(memberProfileRepository.invalidateCacheCallCount == 1)
    }

    @Test("변경에 실패하면 에러를 그대로 전파하고 캐시는 건드리지 않는다")
    func executePropagatesErrorWithoutInvalidating() async {
        let repository = MockAuthRepository()
        repository.changeEmailError = AuthTestError.boom
        let memberProfileRepository = SpyMemberProfileRepository()
        let useCase = ChangeEmailUseCase(
            repository: repository,
            memberProfileRepository: memberProfileRepository
        )

        await #expect(throws: AuthTestError.boom) {
            try await useCase.execute(emailVerificationToken: "email-token")
        }
        #expect(memberProfileRepository.invalidateCacheCallCount == 0)
    }
}

/// 프로필 캐시 무효화 호출 횟수만 추적하는 Spy.
private final class SpyMemberProfileRepository:
    MemberProfileRepositoryProtocol, @unchecked Sendable {

    private(set) var invalidateCacheCallCount = 0

    func fetchMyProfile() async throws -> Profile {
        throw AuthTestError.boom
    }

    func invalidateCache() async {
        invalidateCacheCallCount += 1
    }
}
