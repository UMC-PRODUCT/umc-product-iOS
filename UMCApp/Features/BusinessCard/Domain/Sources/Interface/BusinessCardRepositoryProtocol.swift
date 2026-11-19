//
//  BusinessCardRepositoryProtocol.swift
//  BusinessCardDomain
//
//  Created by One on 8/16/26.
//

import Foundation

/// 내 명함 저장소 경계 (MP-F01·F02).
///
/// 앞면은 정본 프로필 파이프라인(`MemberProfileRepositoryProtocol`) 위임 —
/// 편집 저장 후 primeCache 갱신이 그대로 전파돼 MP-F06이 성립한다.
/// 뒷면(공개 연락처·링크)은 구현이 따로 메모리에 들고 있어, 공개 설정을 저장한 쪽이
/// ``invalidateMyCardCache()`` 로 비워야 한다 (#1678).
public protocol BusinessCardRepositoryProtocol: Sendable {
    func fetchMyCard(forceRefresh: Bool) async throws -> MyCard

    /// 다음 ``fetchMyCard(forceRefresh:)`` 가 뒷면을 서버에서 다시 받게 한다.
    func invalidateMyCardCache() async
}
