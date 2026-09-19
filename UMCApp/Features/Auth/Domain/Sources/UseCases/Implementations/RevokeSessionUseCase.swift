//
//  RevokeSessionUseCase.swift
//  AuthDomain
//
//  Created by euijjang97 on 9/19/26.
//

import os.log

private let logger = Logger(subsystem: "UMCApp", category: "Auth")

/// 로그아웃 직전 서버 측 세션 해제 UseCase 구현체
///
/// 푸시 설치 해제를 먼저 보낸다. 인증이 필요한 호출이라 리프레시 토큰을 먼저 폐기하면,
/// 액세스 토큰이 만료된 상태에서는 갱신할 길이 없어 해제 요청이 401로 끝난다.
public final class RevokeSessionUseCase: RevokeSessionUseCaseProtocol {

    // MARK: - Property

    private let repository: AuthRepositoryProtocol

    // MARK: - Init

    public init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    public func execute() async {
        do {
            try await repository.unregisterPushInstallation()
        } catch {
            logger.error(
                "[Logout] 푸시 설치 해제 실패: \(error.localizedDescription, privacy: .public)"
            )
        }

        do {
            try await repository.revokeRefreshToken()
        } catch {
            logger.error(
                "[Logout] 리프레시 토큰 폐기 실패: \(error.localizedDescription, privacy: .public)"
            )
        }
    }
}
