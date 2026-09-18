//
//  DeleteMemberRequestDTO.swift
//  MyPageData
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation

/// 회원 탈퇴 요청 DTO
///
/// `DELETE /api/v1/member` 요청 바디로 사용됩니다. 연동된 Provider의 access token을 함께 보내면
/// 서버가 해당 Provider측 앱 연결도 해제(revoke)합니다. `nil`인 토큰은 키째 빠지고, 서버는 그
/// Provider의 revoke만 건너뛴 채 탈퇴를 진행합니다.
public struct DeleteMemberRequestDTO: Encodable {
    /// Google 연동 해제용 액세스 토큰
    public let googleAccessToken: String?
    /// Kakao 연동 해제용 액세스 토큰
    public let kakaoAccessToken: String?

    public init(googleAccessToken: String?, kakaoAccessToken: String?) {
        self.googleAccessToken = googleAccessToken
        self.kakaoAccessToken = kakaoAccessToken
    }
}
