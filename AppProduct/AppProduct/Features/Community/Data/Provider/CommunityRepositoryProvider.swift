//
//  CommunityRepositoryProvider.swift
//  AppProduct
//
//  Created by 김미주 on 2/3/26.
//

import Foundation

protocol CommunityRepositoryProviding {
    var communityRepository: CommunityRepositoryProtocol { get }
}

final class CommunityRepositoryProvider: CommunityRepositoryProviding {
    // MARK: - Property
    
    let communityRepository: CommunityRepositoryProtocol
    
    // MARK: - Init
    init(communityRepository: CommunityRepositoryProtocol) {
        self.communityRepository = communityRepository
    }
}

// MARK: - Factory

extension CommunityRepositoryProvider {
    /// Mock Repository Provider
    static func mock() -> CommunityRepositoryProvider {
        CommunityRepositoryProvider(
            communityRepository: MockCommunityRepository()
        )
    }
}
