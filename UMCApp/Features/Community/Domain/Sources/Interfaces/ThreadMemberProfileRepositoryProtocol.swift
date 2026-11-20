//
//  ThreadMemberProfileRepositoryProtocol.swift
//  CommunityDomain
//
//  Created by euijjang97 on 11/19/26.
//

import CoreDomain

/// 스레드에서 연 다른 회원의 공개 프로필 조회 계약 (#1681).
///
/// 서버 `GET /api/v1/member/profile/{memberId}`(MEMBER-101)는 비공개로 둔 링크를 `null` 로 준다.
public protocol ThreadMemberProfileRepositoryProtocol: Sendable {
    func fetchProfile(memberId: String) async throws -> Profile
}
