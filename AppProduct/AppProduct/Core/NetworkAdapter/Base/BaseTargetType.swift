//
//  BaseTargetType.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/3/26.
//

import Foundation
import Moya

/// 모든 API가 공유하는 기본 TargetType 프로토콜
///
/// Moya의 `TargetType`을 확장하여 공통 설정을 제공합니다.
///
/// ## 사용 예시
/// ```swift
/// enum UserAPI: BaseTargetType {
///     case getMe
///     case updateProfile(name: String)
///
///     var path: String {
///         switch self {
///         case .getMe: return "/users/me"
///         case .updateProfile: return "/users/me"
///         }
///     }
///
///     var method: Moya.Method {
///         switch self {
///         case .getMe: return .get
///         case .updateProfile: return .put
///         }
///     }
///
///     var task: Moya.Task {
///         switch self {
///         case .getMe:
///             return .requestPlain
///         case .updateProfile(let name):
///             return .requestParameters(
///                 parameters: ["name": name],
///                 encoding: JSONEncoding.default
///             )
///         }
///     }
/// }
/// ```
protocol BaseTargetType: TargetType {}

// MARK: - Default Implementation

extension BaseTargetType {

    /// API 서버 기본 URL
    ///
    /// `Config.baseURL`에서 가져옵니다 (Secrets.xcconfig → Info.plist)
    var baseURL: URL {
        guard let url = URL(string: Config.baseURL) else {
            fatalError("Invalid BASE_URL in Config")
        }
        return url
    }

    /// 공통 HTTP 헤더
    var headers: [String: String]? {
        ["Content-Type": "application/json"]
    }

    /// 응답 검증 타입
    ///
    /// 2xx 응답만 성공으로 처리
    var validationType: ValidationType {
        .successCodes
    }
}
