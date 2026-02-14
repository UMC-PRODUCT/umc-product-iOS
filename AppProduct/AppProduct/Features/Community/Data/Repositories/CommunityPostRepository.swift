//
//  CommunityPostRepository.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation
import Moya

final class CommunityPostRepository: CommunityPostRepositoryProtocol {
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
    
    // MARK: - Functions
    
    func postPosts(request: PostRequestDTO) async throws {
        let response = try await adapter.request(
            CommunityPostRouter.postPosts(request: request)
        )
        let apiResponse = try decoder.decode(
            APIResponse<PostListResponse>.self,
            from: response.data
        )
        _ = try apiResponse.unwrap()
    }
    
    func postLightning(request: CreateLightningPostRequestDTO) async throws {
        let response = try await adapter.request(
            CommunityPostRouter.postLighting(request: request)
        )
        let apiResponse = try decoder.decode(
            APIResponse<PostListResponse>.self,
            from: response.data
        )
        _ = try apiResponse.unwrap()
    }
    
    func patchPosts(postId: Int, request: PostRequestDTO) async throws {
        let response = try await adapter.request(
            CommunityPostRouter.patchPosts(postId: postId, request: request)
        )
        let apiResponse = try decoder.decode(
            APIResponse<PostListResponse>.self,
            from: response.data
        )
        _ = try apiResponse.unwrap()
    }
    
    func patchLightning(postId: Int, request: CreateLightningPostRequestDTO) async throws {
        let response = try await adapter.request(
            CommunityPostRouter.patchLighting(postId: postId, request: request)
        )
        let apiResponse = try decoder.decode(
            APIResponse<PostListResponse>.self,
            from: response.data
        )
        _ = try apiResponse.unwrap()
    }
}
