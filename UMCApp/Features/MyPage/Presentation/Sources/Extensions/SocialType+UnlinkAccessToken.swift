//
//  SocialType+UnlinkAccessToken.swift
//  MyPagePresentation
//
//  Created by euijjang97 on 9/19/26.
//

import CoreNetwork
import UMCFoundation

extension SocialType {

    /// Provider측 앱 연결 해제(revoke)에 쓸 access token을 소셜 로그인으로 발급받는다.
    ///
    /// 서버는 Kakao·Google만 이 토큰으로 revoke한다. Apple은 서버에 저장된 refresh token으로
    /// 직접 revoke하므로 두 토큰 모두 `nil`이다.
    @MainActor
    func fetchUnlinkAccessTokens(
        kakaoLoginManager: KakaoLoginManaging,
        googleLoginManager: GoogleLoginManaging
    ) async throws -> (googleAccessToken: String?, kakaoAccessToken: String?) {
        switch self {
        case .kakao:
            return (nil, try await kakaoLoginManager.fetchAccessToken())
        case .apple:
            return (nil, nil)
        case .google:
            return (try await googleLoginManager.fetchAccessToken(), nil)
        }
    }

    /// 연동된 소셜마다 연결 해제용 access token을 발급받아 하나로 합친다.
    ///
    /// 발급에 실패하거나 사용자가 로그인 창을 닫은 Provider는 토큰을 비운 채 넘어간다.
    /// 탈퇴는 Provider 연결 해제보다 우선이라, 소셜 계정에 다시 로그인하지 못하는 사용자도
    /// 탈퇴할 수 있어야 한다. 토큰이 빈 Provider는 서버가 revoke만 건너뛴다.
    @MainActor
    static func fetchAvailableUnlinkAccessTokens(
        for socials: [SocialType],
        kakaoLoginManager: KakaoLoginManaging,
        googleLoginManager: GoogleLoginManaging
    ) async -> (googleAccessToken: String?, kakaoAccessToken: String?) {
        var googleAccessToken: String?
        var kakaoAccessToken: String?

        for social in Set(socials) {
            let tokens = try? await social.fetchUnlinkAccessTokens(
                kakaoLoginManager: kakaoLoginManager,
                googleLoginManager: googleLoginManager
            )
            googleAccessToken = googleAccessToken ?? tokens?.googleAccessToken
            kakaoAccessToken = kakaoAccessToken ?? tokens?.kakaoAccessToken
        }

        return (googleAccessToken, kakaoAccessToken)
    }
}
