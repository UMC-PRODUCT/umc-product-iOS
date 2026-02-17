//
//  PostCommentUseCaseProtocol.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation

/// 댓글 작성 UseCase Protocol
protocol PostCommentUseCaseProtocol {
    func execute(postId: Int, request: PostCommentRequest) async throws
}
