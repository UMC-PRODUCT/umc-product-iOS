//
//  CommunityDetailRouter.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation
internal import Alamofire
import Moya

enum CommunityDetailRouter {
    case deletePosts(postId: Int) // 게시글 삭제
    case deleteComments(postId: Int, commentId: Int) // 댓글 삭제
    
    case getComments(postId: Int) // 댓글 조회
    case getPostDetail(postId: Int) // 게시글 상세 조회
    
    case postScrap(postId: Int) // 스크랩 토글
    case postLike(postId: Int) // 좋아요 토글
    case postComments(postId: Int, request: PostCommentRequest) // 댓글 작성
}

extension CommunityDetailRouter: BaseTargetType {
    // MARK: - Path
    var path: String {
        switch self {
        case .deletePosts(let postId):
            return "/api/v1/posts/\(postId)"
        case .deleteComments(let postId, let commentId):
            return "/api/v1/posts/\(postId)/comments/\(commentId)"
        case .getComments(let postId):
            return "/api/v1/posts/\(postId)/comments"
        case .getPostDetail(let postId):
            return "/api/v1/posts/\(postId)"
        case .postScrap(let postId):
            return "/api/v1/posts/\(postId)/scrap"
        case .postLike(let postId):
            return "/api/v1/posts/\(postId)/like"
        case .postComments(let postId, _):
            return "/api/v1/posts/\(postId)/comments"
        }
    }
    
    // MARK: - Method
    var method: Moya.Method {
        switch self {
        case .deleteComments, .deletePosts:
            return .delete
        case .getComments, .getPostDetail:
            return .get
        case .postComments, .postLike, .postScrap:
            return .post
        }
    }
    
    // MARK: - Task
    var task: Moya.Task {
        switch self {
        case .deletePosts, .deleteComments, .getComments, .getPostDetail, .postLike, .postScrap:
            return .requestPlain
        case .postComments(_, let request):
            return .requestJSONEncodable(request)
        }
    }
}
