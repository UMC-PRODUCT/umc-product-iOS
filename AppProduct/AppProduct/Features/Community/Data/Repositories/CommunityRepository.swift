//
//  CommunityRepository.swift
//  AppProduct
//
//  Created by 김미주 on 2/14/26.
//

import Foundation
import Moya

/// Community Repository 구현체
final class CommunityRepository: CommunityRepositoryProtocol {
    // MARK: - Properties
    
    private let adapter: MoyaNetworkAdapter
    private let decoder: JSONDecoder
    
    // MARK: - Init
    
    init(
        adapter: MoyaNetworkAdapter,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.adapter = adapter
        self.decoder = decoder
    }
    
    // MARK: - Function
    
    func getTrophies(
        query: TrophyListQuery
    ) async throws -> [CommunityFameItemModel] {
        let response = try await adapter.request(CommunityRouter.getTrophies(query: query))
        let apiResponse = try decoder.decode(
            APIResponse<[TrophyListResponse]>.self,
            from: response.data
        )
        
        return try apiResponse.unwrap().map { $0.toFameItem() }
    }
    
    func getPosts(
        query: PostListQuery
    ) async throws -> (items: [CommunityItemModel], hasNext: Bool) {
        let response = try await adapter.request(CommunityRouter.getPosts(query: query))
        let apiResponse = try decoder.decode(
            APIResponse<PageDTO<PostListItemDTO>>.self,
            from: response.data
        )
        
        let page = try apiResponse.unwrap()
        return (
            items: page.content.map { $0.toCommunityItemModel() },
            hasNext: page.hasNext
        )
    }
}
