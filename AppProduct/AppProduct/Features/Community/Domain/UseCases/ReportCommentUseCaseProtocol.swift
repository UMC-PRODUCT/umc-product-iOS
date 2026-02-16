//
//  ReportCommentUseCaseProtocol.swift
//  AppProduct
//
//  Created by 김미주 on 2/16/26.
//

import Foundation

/// 게시글 신고 UseCase Protocol
protocol ReportCommentUseCaseProtocol {
    func execute(commentId: Int) async throws
}
