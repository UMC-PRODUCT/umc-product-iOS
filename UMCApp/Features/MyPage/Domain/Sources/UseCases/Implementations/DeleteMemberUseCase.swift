//
//  DeleteMemberUseCase.swift
//  MyPage
//
//  Created by 김동민 on 7/4/26.
//

import Foundation
import UMCFoundation

/// 회원 탈퇴 UseCase 구현체
public final class DeleteMemberUseCase: DeleteMemberUseCaseProtocol {
    
    // MARK: - Property
    
    private let repository: MyPageRepositoryProtocol
    
    /// 전달한 access token이 연동된 계정의 것이 아닐 때 서버가 내려주는 코드
    /// (`OAUTH_INVALID_ACCESS_TOKEN`). 이 경우 서버는 탈퇴 전체를 롤백한다.
    private static let accessTokenOwnerMismatchCode = "AUTHENTICATION-0009"
    
    // MARK: - Function
    
    public init(repository: MyPageRepositoryProtocol) {
        self.repository = repository
    }
    
    /// 토큰 소유자 불일치로 거부되면 토큰 없이 한 번 더 보낸다.
    ///
    /// 소셜 로그인 창에서 연동 계정과 다른 계정을 고르면(예: 카카오톡 앱에 다른 계정이 로그인됨)
    /// 매번 같은 토큰이 발급돼 탈퇴가 영영 막힌다. Provider 연결 해제보다 탈퇴가 우선이므로
    /// revoke를 포기하고 탈퇴만 진행한다.
    public func execute(googleAccessToken: String?, kakaoAccessToken: String?) async throws {
        do {
            try await repository.deleteMember(
                googleAccessToken: googleAccessToken,
                kakaoAccessToken: kakaoAccessToken
            )
        } catch let error as RepositoryError
            where error.code == Self.accessTokenOwnerMismatchCode
            && (googleAccessToken != nil || kakaoAccessToken != nil) {
            try await repository.deleteMember(googleAccessToken: nil, kakaoAccessToken: nil)
        }
    }
}
