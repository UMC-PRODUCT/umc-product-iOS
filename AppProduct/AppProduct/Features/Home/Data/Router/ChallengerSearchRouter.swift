//
//  ChallengerSearchRouter.swift
//  AppProduct
//
//  Created by Claude on 2/13/26.
//

import Foundation
internal import Alamofire
import Moya

/// 챌린저 검색 API 라우터
///
/// 챌린저 검색에 필요한 API 엔드포인트를 정의합니다.
///
/// - SeeAlso: ``ChallengerSearchRepository``, ``ChallengerSearchRequestDTO``
enum ChallengerSearchRouter {
    /// 챌린저 전역 검색 (Cursor 기반 페이지네이션)
    case searchGlobal(query: ChallengerSearchRequestDTO)
}

extension ChallengerSearchRouter: BaseTargetType {

    // MARK: - Path

    var path: String {
        switch self {
        case .searchGlobal:
            return "/api/v1/challenger/search/global"
        }
    }

    // MARK: - Method

    var method: Moya.Method {
        switch self {
        case .searchGlobal:
            return .get
        }
    }

    // MARK: - Task

    var task: Moya.Task {
        switch self {
        case .searchGlobal(let query):
            return .requestParameters(
                parameters: query.queryItems,
                encoding: URLEncoding.queryString
            )
        }
    }
}
