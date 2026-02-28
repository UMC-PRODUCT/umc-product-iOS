//
//  CreateLightningUseCaseProtocol.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation

// 번개글 작성 UseCase Protocol
protocol CreateLightningUseCaseProtocol {
    func execute(request: CreateLightningPostRequestDTO) async throws
}
