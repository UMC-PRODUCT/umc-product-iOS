//
//  SearchPostUseCaseProtocol.swift
//  AppProduct
//
//  Created by 김미주 on 2/18/26.
//

import Foundation

/// 커뮤니티 게시글 검색 UseCase Protocol
protocol SearchPostUseCaseProtocol {
    func execute(query: PostSearchQuery) async throws -> (items: [CommunityItemModel], hasNext: Bool)
}
