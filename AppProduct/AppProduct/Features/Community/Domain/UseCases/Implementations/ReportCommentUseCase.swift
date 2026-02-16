//
//  ReportCommentUseCase.swift
//  AppProduct
//
//  Created by 김미주 on 2/16/26.
//

import Foundation

/// 댓글 신고 UseCase
final class ReportCommentUseCase: ReportCommentUseCaseProtocol {
    private let repository: CommunityDetailRepositoryProtocol

    init(repository: CommunityDetailRepositoryProtocol) {
        self.repository = repository
    }

    func execute(commentId: Int) async throws {
        try await repository.postCommentReport(commentId: commentId)
    }
}
