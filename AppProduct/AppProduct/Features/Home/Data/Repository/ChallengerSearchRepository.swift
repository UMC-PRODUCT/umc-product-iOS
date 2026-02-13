//
//  ChallengerSearchRepository.swift
//  AppProduct
//
//  Created by Claude on 2/13/26.
//

import Foundation
import Moya

/// 챌린저 검색 Repository 구현체
///
/// `ChallengerSearchRepositoryProtocol`을 구현하며,
/// `ChallengerSearchRouter`를 통해 챌린저 검색 API를 호출합니다.
final class ChallengerSearchRepository: ChallengerSearchRepositoryProtocol, @unchecked Sendable {

    // MARK: - Property

    /// Moya 기반 네트워크 어댑터
    private let adapter: MoyaNetworkAdapter

    /// JSON 디코더
    private let decoder: JSONDecoder

    // MARK: - Init

    /// - Parameters:
    ///   - adapter: API 요청을 처리할 네트워크 어댑터
    ///   - decoder: JSON 디코딩에 사용할 디코더 (기본값: JSONDecoder)
    init(
        adapter: MoyaNetworkAdapter,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.adapter = adapter
        self.decoder = decoder
    }

    // MARK: - Function

    func searchChallengers(
        query: ChallengerSearchRequestDTO
    ) async throws -> ChallengerSearchResponseDTO {
        let response = try await adapter.request(
            ChallengerSearchRouter.searchGlobal(query: query)
        )
        let apiResponse = try decoder.decode(
            APIResponse<ChallengerSearchResponseDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap()
    }
}
