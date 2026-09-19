//
//  SocialTypeUnlinkAccessTokenTests.swift
//  MyPagePresentationTests
//
//  Created by euijjang97 on 9/19/26.
//

import Testing
import CoreNetwork
import UMCFoundation
@testable import MyPagePresentation

@MainActor
@Suite("SocialType — 회원 탈퇴용 연결 해제 토큰 수집")
struct SocialTypeUnlinkAccessTokenTests {

    @Test("카카오·구글이 모두 연동돼 있으면 두 토큰을 모두 받는다")
    func collectsBothTokens() async {
        let kakao = CountingKakaoLoginManager()
        let google = CountingGoogleLoginManager()

        let tokens = await SocialType.fetchAvailableUnlinkAccessTokens(
            for: [.kakao, .apple, .google],
            kakaoLoginManager: kakao,
            googleLoginManager: google
        )

        #expect(tokens.kakaoAccessToken == "kakao-token")
        #expect(tokens.googleAccessToken == "google-token")
        #expect(kakao.callCount == 1)
        #expect(google.callCount == 1)
    }

    @Test("카카오 로그인을 취소해도 나머지 Provider 토큰은 받고 카카오만 비운다")
    func skipsCancelledProvider() async {
        let kakao = CountingKakaoLoginManager()
        kakao.error = SocialLoginError.cancelled
        let google = CountingGoogleLoginManager()

        let tokens = await SocialType.fetchAvailableUnlinkAccessTokens(
            for: [.kakao, .google],
            kakaoLoginManager: kakao,
            googleLoginManager: google
        )

        #expect(tokens.kakaoAccessToken == nil)
        #expect(tokens.googleAccessToken == "google-token")
    }

    @Test("애플만 연동됐거나 연동이 없으면 로그인 창을 띄우지 않는다")
    func appleOnlyRequestsNoLogin() async {
        let kakao = CountingKakaoLoginManager()
        let google = CountingGoogleLoginManager()

        for socials in [[SocialType.apple], []] {
            let tokens = await SocialType.fetchAvailableUnlinkAccessTokens(
                for: socials,
                kakaoLoginManager: kakao,
                googleLoginManager: google
            )
            #expect(tokens.kakaoAccessToken == nil)
            #expect(tokens.googleAccessToken == nil)
        }
        #expect(kakao.callCount == 0)
        #expect(google.callCount == 0)
    }
}

// MARK: - Stubs

private final class CountingKakaoLoginManager: KakaoLoginManaging, @unchecked Sendable {
    var error: Error?
    private(set) var callCount = 0

    func login() async throws -> (accessToken: String, email: String) {
        ("kakao-token", "kakao@umc.dev")
    }

    func fetchAccessToken() async throws -> String {
        callCount += 1
        if let error { throw error }
        return "kakao-token"
    }
}

private final class CountingGoogleLoginManager: GoogleLoginManaging, @unchecked Sendable {
    private(set) var callCount = 0

    func login() async throws -> (accessToken: String, email: String?) {
        ("google-token", nil)
    }

    func fetchAccessToken() async throws -> String {
        callCount += 1
        return "google-token"
    }
}
