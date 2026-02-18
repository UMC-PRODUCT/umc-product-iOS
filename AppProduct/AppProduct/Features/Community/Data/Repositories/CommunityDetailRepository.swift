//
//  CommunityDetailRepository.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation
import Moya

final class CommunityDetailRepository: CommunityDetailRepositoryProtocol {
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
    
    func deletePost(postId: Int) async throws {
        let response = try await adapter.request(
            CommunityDetailRouter.deletePosts(postId: postId)
        )
        let apiResponse = try decoder.decode(
            APIResponse<EmptyResult>.self,
            from: response.data
        )
        try apiResponse.validateSuccess()
    }
    
    func deleteComment(postId: Int, commentId: Int) async throws {
        let response = try await adapter.request(
            CommunityDetailRouter.deleteComments(postId: postId, commentId: commentId)
        )
        let apiResponse = try decoder.decode(
            APIResponse<EmptyResult>.self,
            from: response.data
        )
        try apiResponse.validateSuccess()
    }
    
    func getComments(postId: Int) async throws -> [CommunityCommentModel] {
        let response = try await adapter.request(
            CommunityDetailRouter.getComments(postId: postId)
        )
        let apiResponse = try decoder.decode(
            APIResponse<[CommentDTO]>.self,
            from: response.data
        )
        return try apiResponse.unwrap().map { $0.toCommentModel() }
    }
    
    func getPostDetail(postId: Int) async throws -> CommunityItemModel {
        let response = try await adapter.request(
            CommunityDetailRouter.getPostDetail(postId: postId)
        )
        let apiResponse = try decoder.decode(
            APIResponse<PostDetailDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap().toCommunityItemModel()
    }
    
    func postScrap(postId: Int) async throws {
        let response = try await adapter.request(
            CommunityDetailRouter.postScrap(postId: postId)
        )
        let apiResponse = try decoder.decode(
            APIResponse<CommunityScrapDTO>.self,
            from: response.data
        )
        _ = try apiResponse.unwrap()
    }
    
    func postLike(postId: Int) async throws {
        let response = try await adapter.request(
            CommunityDetailRouter.postLike(postId: postId)
        )
        let apiResponse = try decoder.decode(
            APIResponse<CommunityLikeDTO>.self,
            from: response.data
        )
        _ = try apiResponse.unwrap()
    }
    
    func postComment(postId: Int, request: PostCommentRequest) async throws {
        let response = try await adapter.request(
            CommunityDetailRouter.postComments(postId: postId, request: request)
        )
        let apiResponse = try decoder.decode(
            APIResponse<CommentDTO>.self,
            from: response.data
        )
        _ = try apiResponse.unwrap()
    }
    
    func postPostReport(postId: Int) async throws {
        do {
            let response = try await adapter.request(
                CommunityDetailRouter.postPostReports(postId: postId)
            )
            do {
                let apiResponse = try decoder.decode(
                    APIResponse<EmptyResult>.self,
                    from: response.data
                )
                try apiResponse.validateSuccess()
            } catch {
                if response.statusCode == 409 {
                    throw RepositoryError.serverError(code: "409", message: "이미 신고한 게시글입니다.")
                }
                guard (200..<300).contains(response.statusCode) else {
                    throw error
                }
            }
        } catch let networkError as NetworkError {
            if case .requestFailed(let statusCode, _) = networkError, statusCode == 409 {
                throw RepositoryError.serverError(code: "409", message: "이미 신고한 게시글입니다.")
            }
            throw networkError
        }
    }
    
    func postCommentReport(commentId: Int) async throws {
        do {
            let response = try await adapter.request(
                CommunityDetailRouter.postCommentReports(commentId: commentId)
            )
            do {
                let apiResponse = try decoder.decode(
                    APIResponse<EmptyResult>.self,
                    from: response.data
                )
                try apiResponse.validateSuccess()
            } catch {
                if response.statusCode == 409 {
                    throw RepositoryError.serverError(code: "409", message: "이미 신고한 댓글입니다.")
                }
                guard (200..<300).contains(response.statusCode) else {
                    throw error
                }
            }
        } catch let networkError as NetworkError {
            if case .requestFailed(let statusCode, _) = networkError, statusCode == 409 {
                throw RepositoryError.serverError(code: "409", message: "이미 신고한 댓글입니다.")
            }
            throw networkError
        }
    }
}
