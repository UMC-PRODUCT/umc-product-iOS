//
//  ThreadMemberProfileRepository.swift
//  CommunityData
//
//  Created by euijjang97 on 11/19/26.
//

import Foundation
import CommunityDomain
import CoreDomain
import CoreNetwork
import UMCFoundation

/// 스레드에서 연 다른 회원의 공개 프로필 저장소 (#1681).
///
/// 응답 모양은 내 프로필(`/member/me`)과 같아 정본 DTO(`MemberProfileResponseDTO`)와 그 변환을
/// 그대로 쓴다. 캐시하지 않는다 — 시트를 열 때마다 상대가 바꾼 공개 설정을 반영한다.
public final class ThreadMemberProfileRepository:
    ThreadMemberProfileRepositoryProtocol, @unchecked Sendable {

    // MARK: - Property

    private let networkRequesting: any CommunityThreadNetworkRequesting

    // MARK: - Init

    public convenience init(adapter: MoyaNetworkAdapter) {
        self.init(networkRequesting: adapter)
    }

    init(networkRequesting: any CommunityThreadNetworkRequesting) {
        self.networkRequesting = networkRequesting
    }

    // MARK: - Function

    public func fetchProfile(memberId: String) async throws -> Profile {
        let target = CommunityThreadRouter.getMemberProfile(memberId: memberId)
        let response = try await networkRequesting.request(target)
        do {
            return try JSONDecoder()
                .decode(APIResponse<MemberProfileResponseDTO>.self, from: response.data)
                .unwrap()
                .toDomain()
        } catch let decodingError as DecodingError {
            throw RepositoryError.decodingError(detail: "\(target.path): \(decodingError)")
        }
    }
}
