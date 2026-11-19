//
//  CardContactSettingsRepository.swift
//  MyPageData
//
//  Created by euijjang97 on 11/19/26.
//

import Foundation
import CoreDomain
import CoreNetwork
import MyPageDomain
import UMCFoundation

/// 명함 연락처·링크와 공개 여부 저장소 (#1678).
///
/// 서버 명함 수정 API(MEMBER-105 조회 · MEMBER-006 저장)를 쓴다. 예전 링크 수정 API
/// (`PATCH /member/profile/links`)는 공개 여부와 연락 이메일을 다루지 않아 이 경로로 바꿨다.
public final class CardContactSettingsRepository:
    CardContactSettingsRepositoryProtocol, @unchecked Sendable {

    // MARK: - Property

    private let adapter: any MyPageNetworkRequesting
    private let memberProfileRepository: MemberProfileRepositoryProtocol
    private let decoder = JSONDecoder()

    // MARK: - Init

    /// 운영 이니셜라이저 — 구체 `MoyaNetworkAdapter` 를 주입받습니다.
    public convenience init(
        adapter: MoyaNetworkAdapter,
        memberProfileRepository: MemberProfileRepositoryProtocol
    ) {
        self.init(networkRequesting: adapter, memberProfileRepository: memberProfileRepository)
    }

    /// 테스트 seam (``MyPageRepository`` 와 같은 이유).
    init(
        networkRequesting: any MyPageNetworkRequesting,
        memberProfileRepository: MemberProfileRepositoryProtocol
    ) {
        self.adapter = networkRequesting
        self.memberProfileRepository = memberProfileRepository
    }

    // MARK: - Function

    public func fetchCardContactSettings() async throws -> CardContactSettings {
        try await request(MyPageRouter.getMyBusinessCardEdit)
    }

    /// 저장 응답은 프로필이 아니라 명함 수정 화면 응답이라 프로필 캐시를 채울 수 없다.
    /// 그래서 저장 뒤 프로필을 새로 읽어 캐시를 맞춘다 — 그대로 두면 설정 화면의 외부 링크가
    /// 저장 전 값으로 남는다. 이 재조회가 실패해도 저장은 끝났으므로 결과를 그대로 돌려준다.
    public func updateCardContactSettings(
        _ settings: CardContactSettings
    ) async throws -> CardContactSettings {
        let saved = try await request(
            MyPageRouter.patchMyBusinessCard(
                request: EditBusinessCardRequestDTO(settings: settings)
            )
        )
        _ = try? await memberProfileRepository.fetchMyProfile(forceRefresh: true)
        return saved
    }

    // MARK: - Private Function

    /// 서버 검증 실패(잘못된 이메일 형식 등)는 서버 문구가 사용자에게 보이도록 바꿔 던진다.
    private func request(_ target: MyPageRouter) async throws -> CardContactSettings {
        do {
            let response = try await adapter.request(target)
            return try decoder
                .decode(APIResponse<BusinessCardEditResponseDTO>.self, from: response.data)
                .unwrap()
                .toDomain()
        } catch let error as NetworkError {
            throw MyPageRepository.parseServerError(from: error) ?? error
        }
    }
}
