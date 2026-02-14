//
//  UpdatePostUseCaseProtocol.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation

// 게시글 수정 UseCase Protocol
protocol UpdatePostUseCaseProtocol {
    func execute(postId: Int, request: PostRequestDTO) async throws
}
