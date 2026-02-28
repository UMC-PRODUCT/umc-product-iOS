//
//  FetchPostDetailUseCaseProtocol.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation

/// 게시글 상세 조회 UseCase Protocol
protocol FetchPostDetailUseCaseProtocol {
    func execute(postId: Int) async throws -> CommunityItemModel
}
