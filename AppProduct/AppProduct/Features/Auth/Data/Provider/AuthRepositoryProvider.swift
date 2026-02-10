//
//  AuthRepositoryProvider.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/9/26.
//

import Foundation

/// Auth Feature에서 사용하는 Repository를 제공하는 Provider Protocol
protocol AuthRepositoryProviding {
    /// Auth 데이터 접근 Repository
    var authRepository: AuthRepositoryProtocol { get }
}

/// Auth Repository Provider 구현
///
/// Mock/Real 구현체 교체 시 이 Provider만 수정하면 됩니다.
final class AuthRepositoryProvider: AuthRepositoryProviding {

    // MARK: - Property

    let authRepository: AuthRepositoryProtocol

    // MARK: - Init

    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }
}

// MARK: - Factory

extension AuthRepositoryProvider {
    /// Mock Repository로 구성된 Provider 생성
    static func mock() -> AuthRepositoryProvider {
        AuthRepositoryProvider(
            authRepository: MockAuthRepository()
        )
    }

    /// 실제 서버 연결 Provider 생성
    static func real(
        adapter: MoyaNetworkAdapter
    ) -> AuthRepositoryProvider {
        AuthRepositoryProvider(
            authRepository: AuthRepository(adapter: adapter)
        )
    }
}
