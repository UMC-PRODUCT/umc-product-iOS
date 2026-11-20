//
//  StubThreadMemberProfileRepository.swift
//  UMCApp
//
//  Created by euijjang97 on 11/19/26.
//

#if DEBUG
import CommunityDomain
import CoreDomain

/// 스레드 프로필 시트(#1681)의 다른 회원 프로필 stub.
///
/// stub 세션에는 서버 인증이 없어 실물 저장소로는 프로필을 못 읽는다. 누구를 눌러도 다른
/// 신원(B)의 프로필을 돌려준다 — B는 Instagram·개인 사이트가 비어 있어 비공개 표시도 보인다.
struct StubThreadMemberProfileRepository: ThreadMemberProfileRepositoryProtocol {

    func fetchProfile(memberId: String) async throws -> Profile {
        StubSessionFixtures.otherMemberProfile
    }
}
#endif
