
//
//  CommunityRouter.swift
//  AppProduct
//
//  Created by euijjang97 on 2/10/26.
//

import Foundation
import Moya
internal import Alamofire

/// 커뮤니티 관련 API 라우터
enum CommunityRouter {
    // MARK: - DELETE
    /// 게시글 삭제
    case deletePost(postId: Int)
    /// 댓글 삭제
    case deleteComment(postId: Int, commentId: Int, query: DeleteCommentQuery)
    
    // MARK: - GET
    /// 상장 목록 조회
    case getTrophies(query: TrophyListQuery)
    /// 게시글 목록 조회
    case getPosts(query: PostListQuery)
    /// 댓글 목록 조회
    case getComments(postId: Int)
    /// 게시글 상세 조회
    case getPost(postId: Int)
    /// 게시글 검색
    case searchPosts(query: PostSearchQuery)
    
    // MARK: - PATCH
    /// 게시글 수정
    case updatePost(postId: Int, body: PostRequestDTO)
    
    // MARK: - POST
    /// 상장 생성
    case createTrophy(body: CreateTrophyRequestDTO)
    /// 일반 게시글 생성
    case createPost(query: ChallengerIdQuery, body: PostRequestDTO)
    /// 게시글 좋아요 토글
    case togglePostLike(postId: Int, query: ChallengerIdQuery)
    /// 댓글 작성
    case createComment(postId: Int, parameters: [String: Any])
    /// 댓글 좋아요 토글
    case toggleCommentLike(postId: Int, commentId: Int, query: ChallengerIdQuery)
    /// 번개글 생성
    case createLightningPost(query: ChallengerIdQuery, body: CreateLightningPostRequestDTO)
}

extension CommunityRouter: BaseTargetType {
    var path: String {
        switch self {
        case .deletePost(let postId):
            return "/api/v1/posts/\(postId)"
        case .deleteComment(let postId, let commentId, _):
            return "/api/v1/posts/\(postId)/comments/\(commentId)"
        case .getTrophies, .createTrophy:
            return "/api/v1/trophies"
        case .getPosts, .createPost:
            return "/api/v1/posts"
        case .getComments(let postId), .createComment(let postId, _):
            return "/api/v1/posts/\(postId)/comments"
        case .getPost(let postId), .updatePost(let postId, _):
            return "/api/v1/posts/\(postId)"
        case .searchPosts:
            return "/api/v1/posts/search"
        case .togglePostLike(let postId, _):
            return "/api/v1/posts/\(postId)/like"
        case .toggleCommentLike(let postId, let commentId, _):
            return "/api/v1/posts/\(postId)/comments/\(commentId)/like"
        case .createLightningPost:
            return "/api/v1/posts/lightning"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .deletePost, .deleteComment:
            return .delete
        case .getTrophies, .getPosts, .getComments, .getPost, .searchPosts:
            return .get
        case .updatePost:
            return .patch
        case .createTrophy, .createPost, .togglePostLike, .createComment, .toggleCommentLike, .createLightningPost:
            return .post
        }
    }
    
    var task: Moya.Task {
        switch self {
        case .deletePost, .getComments, .getPost:
            return .requestPlain
            
        case .deleteComment(_, _, let query):
            return .requestParameters(parameters: query.toParameters, encoding: URLEncoding.queryString)
            
        case .getTrophies(let query):
            return .requestParameters(parameters: query.toParameters, encoding: URLEncoding.queryString)
            
        case .getPosts(let query):
            return .requestParameters(parameters: query.toParameters, encoding: URLEncoding.queryString)
            
        case .searchPosts(let query):
            return .requestParameters(parameters: query.toParameters, encoding: URLEncoding.queryString)
            
        case .updatePost(_, let body):
            return .requestJSONEncodable(body)
            
        case .createTrophy(let body):
            return .requestJSONEncodable(body)
            
        case .createPost(let query, let body):
            return .requestCompositeParameters(bodyParameters: (try? body.asDictionary()) ?? [:], bodyEncoding: JSONEncoding.default, urlParameters: query.toParameters)
            
        case .togglePostLike(_, let query):
             return .requestParameters(parameters: query.toParameters, encoding: URLEncoding.queryString)
            
        case .toggleCommentLike(_, _, let query):
            return .requestParameters(parameters: query.toParameters, encoding: URLEncoding.queryString)
            
        case .createComment(_, let parameters):
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
            
        case .createLightningPost(let query, let body):
            return .requestCompositeParameters(bodyParameters: (try? body.asDictionary()) ?? [:], bodyEncoding: JSONEncoding.default, urlParameters: query.toParameters)
        }
    }
}


// Encodable Extension for generic dictionary conversion
extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }
}


