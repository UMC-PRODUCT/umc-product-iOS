//
//  DeletePostUseCaseProtocol.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation

/// 게시글 삭제 UseCase Protocol
protocol DeletePostUseCaseProtocol {
    func execute(postId: Int) async throws
}
