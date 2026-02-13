//
//  FetchRecentNoticesUseCase.swift
//  AppProduct
//
//  Created by Claude on 2/12/26.
//

import Foundation

/// 최근 공지 조회 UseCase 구현
final class FetchRecentNoticesUseCase: FetchRecentNoticesUseCaseProtocol {
    private let repository: HomeRepositoryProtocol

    init(repository: HomeRepositoryProtocol) {
        self.repository = repository
    }

    func execute(
        query: NoticeListRequestDTO
    ) async throws -> [RecentNoticeData] {
        try await repository.getRecentNotices(query: query)
    }
}
