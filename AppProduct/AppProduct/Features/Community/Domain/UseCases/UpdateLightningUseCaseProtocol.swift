//
//  UpdateLightningUseCaseProtocol.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation

// 번개글 수정 UseCase Protocol
protocol UpdateLightningUseCaseProtocol {
    func execute(postId: Int, request: CreateLightningPostRequestDTO) async throws
}
