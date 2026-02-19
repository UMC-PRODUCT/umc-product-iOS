//
//  CommunityPostRouter.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation
internal import Alamofire
import Moya

enum CommunityPostRouter {
    case postPosts(request: PostRequestDTO) // 일반 게시글 생성
    case postLighting(request: CreateLightningPostRequestDTO) // 번개글 생성
    case patchPosts(postId: Int, request: PostRequestDTO) // 일반 게시글 수정
    case patchLighting(postId: Int, request: CreateLightningPostRequestDTO) // 번개글 수정
}

extension CommunityPostRouter: BaseTargetType {
    // MARK: - Path
    var path: String {
        switch self {
        case .postPosts:
            return "/api/v1/posts"
        case .postLighting:
            return "/api/v1/posts/lightning"
        case .patchPosts(let postId, _):
            return "/api/v1/posts/\(postId)"
        case .patchLighting(let postId, _):
            return "/api/v1/posts/\(postId)/lightning"
        }
    }
    
    // MARK: - Method
    var method: Moya.Method {
        switch self {
        case .postPosts, .postLighting:
            return .post
        case .patchPosts, .patchLighting:
            return .patch
        }
    }
    
    // MARK: - Task
    var task: Moya.Task {
        switch self {
        case .postPosts(let request):
            return .requestJSONEncodable(request)
        case .postLighting(let request):
            return .requestJSONEncodable(request)
        case .patchPosts(_, let request):
            return .requestJSONEncodable(request)
        case .patchLighting(_, let request):
            return .requestJSONEncodable(request)
        }
    }
}
