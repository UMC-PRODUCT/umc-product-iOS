//
//  FetchCommunityItemsUseCaseProtocol.swift
//  AppProduct
//
//  Created by 김미주 on 2/3/26.
//

import Foundation

/// 커뮤니티 게시글 조회 UseCase Protocol
protocol FetchCommunityItemsUseCaseProtocol {
    func execute(query: PostListQuery) async throws -> (items: [CommunityItemModel], hasNext: Bool)
}
