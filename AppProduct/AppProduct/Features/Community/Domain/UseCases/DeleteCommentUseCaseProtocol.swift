//
//  DeleteCommentUseCaseProtocol.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation

/// 댓글 삭제 UseCase Protocol
protocol DeleteCommentUseCaseProtocol {
    func execute(postId: Int, commentId: Int) async throws
}
