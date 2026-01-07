//
//  Publisher+AppError.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/7/25.
//

import Combine
import Foundation
import Moya

extension Publisher where Failure == MoyaError {
    /// MoyaError를 AppError로 변환하는 Publisher
    func mapToAppError() -> AnyPublisher<Output, AppError> {
        mapError { $0.toAppError() }
            .eraseToAnyPublisher()
    }
}

extension Publisher where Failure == Error {
    /// 일반 Error를 AppError로 변환하는 Publisher
    func mapToAppError() -> AnyPublisher<Output, AppError> {
        mapError { error in
            if let moyaError = error as? MoyaError {
                return moyaError.toAppError()
            } else if let apiError = error as? APIError {
                return .api(apiError)
            } else if let authError = error as? AuthError {
                return .auth(authError)
            } else if let validationError = error as? ValidationError {
                return .validation(validationError)
            } else if let domainError = error as? DomainError {
                return .domain(domainError)
            } else if let appError = error as? AppError {
                return appError
            } else {
                return .unknown(message: error.localizedDescription)
            }
        }
        .eraseToAnyPublisher()
    }
}
