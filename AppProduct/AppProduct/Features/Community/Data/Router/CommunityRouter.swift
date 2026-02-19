//
//  CommunityRouter.swift
//  AppProduct
//
//  Created by 김미주 on 2/14/26.
//

internal import Alamofire
import Moya

enum CommunityRouter {
    case getPosts(query: PostListQuery) // 게시글 목록 조회
    case getTrophies(query: TrophyListQuery) // 명예의전당 목록 조회
    case getSearch(query: PostSearchQuery)
}

extension CommunityRouter: BaseTargetType {
    
    // MARK: - Path
    
    var path: String {
        switch self {
        case .getPosts:
            return "/api/v1/posts"
        case .getTrophies:
            return "/api/v1/trophies"
        case .getSearch:
            return "/api/v1/posts/search"
        }
    }
    
    // MARK: - Method
    
    var method: Moya.Method {
        switch self {
        case .getPosts, .getTrophies, .getSearch:
            return .get
        }
    }
    
    // MARK: - Task
    
    var task: Moya.Task {
        switch self {
        case .getPosts(let query):
            return .requestParameters(parameters: query.toParameters, encoding: URLEncoding.queryString)
        case .getTrophies(let query):
            return .requestParameters(parameters: query.toParameters, encoding: URLEncoding.queryString)
        case .getSearch(let query):
            return .requestParameters(parameters: query.toParameters, encoding: URLEncoding.queryString)
        }
    }
}
