//
//  FetchFameItemsUseCaseProtocol.swift
//  AppProduct
//
//  Created by 김미주 on 2/3/26.
//

import Foundation

/// 명예의전당 조회 UseCase Protocol
protocol FetchFameItemsUseCaseProtocol {
    func execute() async throws -> [CommunityFameItemModel]
}
