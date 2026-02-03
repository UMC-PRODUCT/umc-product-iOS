//
//  CreatePostUseCaseProtocol.swift
//  AppProduct
//
//  Created by 김미주 on 2/3/26.
//

import Foundation

/// 게시글 작성 UseCase Protocol
protocol CreatePostUseCaseProtocol {
    func execute(request: CreatePostRequest) async throws -> CommunityItemModel
}
