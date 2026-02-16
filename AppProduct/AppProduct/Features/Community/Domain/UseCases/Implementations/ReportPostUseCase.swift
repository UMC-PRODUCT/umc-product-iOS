//
//  ReportPostUseCase.swift
//  AppProduct
//
//  Created by 김미주 on 2/16/26.
//

import Foundation

/// 댓글 신고 UseCase
final class ReportPostUseCase: ReportPostUseCaseProtocol {
    private let repository: CommunityDetailRepositoryProtocol

    init(repository: CommunityDetailRepositoryProtocol) {
        self.repository = repository
    }

    func execute(postId: Int) async throws {
        try await repository.postPostReport(postId: postId)
    }
}
