//
//  DeleteMemberUseCaseTests.swift
//  MyPageDomainTests
//
//  Created by 김동민 on 7/4/26.
//

import Testing
import Foundation
import UMCFoundation
@testable import MyPageDomain

@Suite("DeleteMemberUseCase — Repository 위임 / 토큰 소유자 불일치 재시도")
struct DeleteMemberUseCaseTests {

    private static let ownerMismatchError = RepositoryError.serverError(
        code: "AUTHENTICATION-0009",
        message: "유효하지 않은 OAuth Access Token입니다."
    )

    @Test("execute() 호출 시 전달받은 토큰 그대로 repository.deleteMember()에 위임한다")
    func delegatesToDeleteMemberWithTokens() async throws {
        let mock = MockMyPageRepository()
        let useCase = DeleteMemberUseCase(repository: mock)

        try await useCase.execute(
            googleAccessToken: "google-token",
            kakaoAccessToken: "kakao-token"
        )

        #expect(mock.deleteMemberCallCount == 1)
        #expect(mock.deleteMemberReceivedGoogleAccessTokens == ["google-token"])
        #expect(mock.deleteMemberReceivedKakaoAccessTokens == ["kakao-token"])
    }

    @Test("repository가 에러를 던지면 그대로 전파한다")
    func propagatesError() async {
        let mock = MockMyPageRepository()
        mock.deleteMemberError = MyPageTestError.boom
        let useCase = DeleteMemberUseCase(repository: mock)

        await #expect(throws: MyPageTestError.boom) {
            try await useCase.execute(googleAccessToken: nil, kakaoAccessToken: "kakao-token")
        }
        #expect(mock.deleteMemberCallCount == 1)
    }

    @Test("토큰 소유자 불일치(AUTHENTICATION-0009)면 토큰 없이 한 번 더 탈퇴를 요청한다")
    func retriesWithoutTokensOnOwnerMismatch() async throws {
        let mock = MockMyPageRepository()
        mock.deleteMemberErrorSequence = [Self.ownerMismatchError, nil]
        let useCase = DeleteMemberUseCase(repository: mock)

        try await useCase.execute(googleAccessToken: nil, kakaoAccessToken: "kakao-token")

        #expect(mock.deleteMemberCallCount == 2)
        #expect(mock.deleteMemberReceivedKakaoAccessTokens == ["kakao-token", nil])
        #expect(mock.deleteMemberReceivedGoogleAccessTokens == [nil, nil])
    }

    @Test("토큰 없이 보낸 요청은 AUTHENTICATION-0009여도 재시도하지 않는다")
    func doesNotRetryWithoutTokens() async {
        let mock = MockMyPageRepository()
        mock.deleteMemberError = Self.ownerMismatchError
        let useCase = DeleteMemberUseCase(repository: mock)

        await #expect(throws: Self.ownerMismatchError) {
            try await useCase.execute(googleAccessToken: nil, kakaoAccessToken: nil)
        }
        #expect(mock.deleteMemberCallCount == 1)
    }

    @Test("다른 서버 에러 코드는 재시도하지 않고 그대로 전파한다")
    func doesNotRetryOnOtherServerError() async {
        let otherError = RepositoryError.serverError(code: "MEMBER-0001", message: nil)
        let mock = MockMyPageRepository()
        mock.deleteMemberError = otherError
        let useCase = DeleteMemberUseCase(repository: mock)

        await #expect(throws: otherError) {
            try await useCase.execute(googleAccessToken: "google-token", kakaoAccessToken: nil)
        }
        #expect(mock.deleteMemberCallCount == 1)
    }
}
