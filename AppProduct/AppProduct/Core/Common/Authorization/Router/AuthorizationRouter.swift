//
//  AuthorizationRouter.swift
//  AppProduct
//
//  Created by euijjang97 on 2/17/26.
//

import Foundation
import Moya
internal import Alamofire

/// 공용 리소스 권한 API 라우터
enum AuthorizationRouter: BaseTargetType {
    /// 리소스 권한 조회
    case getResourcePermission(
        resourceType: AuthorizationResourceType,
        resourceId: Int
    )

    var path: String {
        switch self {
        case .getResourcePermission:
            return "/api/v1/authorization/resource-permission"
        }
    }

    var method: Moya.Method {
        switch self {
        case .getResourcePermission:
            return .get
        }
    }

    var task: Task {
        switch self {
        case .getResourcePermission(let resourceType, let resourceId):
            return .requestParameters(
                parameters: [
                    "resourceType": resourceType.rawValue,
                    "resourceId": resourceId
                ],
                encoding: URLEncoding.queryString
            )
        }
    }
}
