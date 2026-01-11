//
//  MoyaError+APIError.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/7/25.
//

import Foundation
import Moya

extension MoyaError {
    /// MoyaError를 APIError로 변환
    func toAPIError() -> APIError {
        switch self {
        case .statusCode(let response):
            return APIError.from(statusCode: response.statusCode)

        case .underlying(let error as NSError, _):
            switch error.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                return .noNetwork
            case NSURLErrorTimedOut:
                return .timeout
            default:
                return .requestFailed(statusCode: error.code, message: error.localizedDescription)
            }

        case .objectMapping(let error, _):
            return .decodingFailed(detail: error.localizedDescription)

        case .jsonMapping, .stringMapping, .imageMapping:
            return .decodingFailed(detail: nil)

        case .requestMapping, .parameterEncoding, .encodableMapping:
            return .invalidURL

        default:
            return .unknown
        }
    }

    /// MoyaError를 AppError로 변환
    func toAppError() -> AppError {
        .api(toAPIError())
    }
}
