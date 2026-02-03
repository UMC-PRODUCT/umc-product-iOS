//
//  FetchCommentsUseCaseProtocol.swift
//  AppProduct
//
//  Created by 김미주 on 2/3/26.
//

import Foundation

/// 게시글 댓글 목록 조회 UseCase Protocol
protocol FetchCommentsUseCaseProtocol {
    func execute(postId: Int) async throws -> [CommunityCommentModel]
}  
