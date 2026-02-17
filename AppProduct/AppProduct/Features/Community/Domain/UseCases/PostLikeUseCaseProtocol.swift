//
//  PostLikeUseCaseProtocol.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation

/// 게시글 좋아요 UseCase Protocol
protocol PostLikeUseCaseProtocol {
    func execute(postId: Int) async throws
}
