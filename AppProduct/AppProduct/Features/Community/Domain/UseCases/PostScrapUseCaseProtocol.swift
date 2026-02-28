//
//  PostScrapUseCaseProtocol.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation

/// 게시글 스크랩 UseCase Protocol
protocol PostScrapUseCaseProtocol {
    func execute(postId: Int) async throws
}
