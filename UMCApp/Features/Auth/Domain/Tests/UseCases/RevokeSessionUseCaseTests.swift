//
//  RevokeSessionUseCaseTests.swift
//  AuthDomainTests
//
//  Created by euijjang97 on 9/19/26.
//

import Testing
@testable import AuthDomain

@Suite("RevokeSessionUseCase — 로그아웃 전 서버 세션 해제")
struct RevokeSessionUseCaseTests {

    @Test("푸시 설치 해제 → 리프레시 토큰 폐기 순서로 호출하고 로컬 정리는 하지 않는다")
    func executeCallsInOrder() async {
        let repository = MockAuthRepository()
        let useCase = RevokeSessionUseCase(repository: repository)

        await useCase.execute()

        #expect(repository.revokeCallLog == ["unregisterPushInstallation", "revokeRefreshToken"])
        #expect(repository.logoutCallCount == 0)
    }

    @Test("푸시 설치 해제가 실패해도 리프레시 토큰 폐기는 계속 호출한다")
    func unregisterFailureStillRevokesToken() async {
        let repository = MockAuthRepository()
        repository.unregisterPushInstallationError = AuthTestError.boom
        let useCase = RevokeSessionUseCase(repository: repository)

        await useCase.execute()

        #expect(repository.revokeCallLog == ["unregisterPushInstallation", "revokeRefreshToken"])
    }

    @Test("두 호출이 모두 실패해도 에러를 던지지 않는다")
    func bothFailuresAreSwallowed() async {
        let repository = MockAuthRepository()
        repository.unregisterPushInstallationError = AuthTestError.boom
        repository.revokeRefreshTokenError = AuthTestError.boom
        let useCase = RevokeSessionUseCase(repository: repository)

        await useCase.execute()

        #expect(repository.revokeCallLog.count == 2)
    }
}
