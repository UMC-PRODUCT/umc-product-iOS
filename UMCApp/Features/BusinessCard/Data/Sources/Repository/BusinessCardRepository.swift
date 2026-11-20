//
//  BusinessCardRepository.swift
//  BusinessCardData
//
//  Created by One on 8/16/26.
//

import Foundation
import os
import CoreDomain
import CoreNetwork
import BusinessCardDomain

/// 내 명함 저장소 (MP-F01·F02).
///
/// 앞면은 정본 프로필 파이프라인(`CachedMemberProfileRepository`)에 위임한다. 명함이 별도
/// 조회를 하면 편집 직후 프로필과 어긋난다. 편집 저장 → primeCache → 여기서 재조회 시
/// 최신 스냅샷이 오므로 MP-F06(캐시 무효화 즉시 갱신)이 추가 코드 없이 성립한다.
///
/// 뒷면 이메일·링크는 정본 프로필 값을 쓰되, 명함 수정 화면 조회(MEMBER-105)의 공개 여부로
/// 비공개 항목을 뺀다 (#1678). 정본 프로필은 공개 여부 없이 값을 모두 주기 때문이다. 공개 여부도
/// 프로필처럼 메모리에 들고 있다 — 매번 읽으면 마이페이지로 돌아올 때마다 왕복이 늘고, 근거리
/// 교환이 인터넷 없이 시작되지 않는다. 공개 여부를 저장하면 ``invalidateMyCardCache()`` 로
/// 비워 다음 조회에서 다시 받는다.
public final class BusinessCardRepository: BusinessCardRepositoryProtocol, @unchecked Sendable {

    // MARK: - Property

    private let memberProfileRepository: MemberProfileRepositoryProtocol
    private let networkRequesting: any BusinessCardNetworkRequesting
    private let decoder = JSONDecoder()
    private let visibilityCache = OSAllocatedUnfairLock(initialState: VisibilityCache())

    // MARK: - Init

    /// 운영 이니셜라이저.
    public convenience init(
        memberProfileRepository: MemberProfileRepositoryProtocol,
        adapter: MoyaNetworkAdapter
    ) {
        self.init(memberProfileRepository: memberProfileRepository, networkRequesting: adapter)
    }

    /// 테스트 seam 주입용 (baseURL fatalError 회피 — ``ActivityStatRepository`` 선례).
    init(
        memberProfileRepository: MemberProfileRepositoryProtocol,
        networkRequesting: any BusinessCardNetworkRequesting
    ) {
        self.memberProfileRepository = memberProfileRepository
        self.networkRequesting = networkRequesting
    }

    // MARK: - Function

    /// 받아 둔 공개 여부가 없는데 조회가 실패하면 명함 전체를 실패로 돌린다. 공개 여부를 모른 채
    /// 프로필 값으로 그리면 비공개로 둔 이메일·링크가 드러난다.
    public func fetchMyCard(forceRefresh: Bool) async throws -> MyCard {
        async let profile = memberProfileRepository.fetchMyProfile(forceRefresh: forceRefresh)
        async let visibility = fetchVisibility(forceRefresh: forceRefresh)
        return try await visibility.applyingVisibility(to: profile.toMyCard())
    }

    public func invalidateMyCardCache() async {
        visibilityCache.withLock { cache in
            cache.response = nil
            cache.generation += 1
        }
    }

    // MARK: - Private Function

    private func fetchVisibility(
        forceRefresh: Bool
    ) async throws -> MyCardVisibilityResponseDTO {
        let cached = visibilityCache.withLock { $0 }
        if !forceRefresh, let response = cached.response {
            return response
        }

        let response = try await networkRequesting.request(
            BusinessCardRouter.getMyBusinessCardEdit
        )
        let visibility = try decoder
            .decode(APIResponse<MyCardVisibilityResponseDTO>.self, from: response.data)
            .unwrap()
        visibilityCache.withLock { cache in
            // 요청 중에 비워졌다면 저장 전 값일 수 있어 담지 않는다.
            guard cache.generation == cached.generation else { return }
            cache.response = visibility
        }
        return visibility
    }
}

/// 마지막으로 받은 공개 여부. 세대 번호는 `CachedMemberProfileRepository`와 같은 용도다.
private struct VisibilityCache: Sendable {
    var response: MyCardVisibilityResponseDTO?
    var generation = 0
}
