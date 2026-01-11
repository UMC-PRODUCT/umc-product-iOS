//
//  Publisher+AppError.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/7/25.
//

import Foundation
import CombineMoya
import Moya
import Combine

// MARK: - CombineMoya Response Extensions

extension Publisher where Output == Response, Failure == MoyaError {
    /// HTTP 200-299 상태 코드 검증
    ///
    /// CombineMoya의 `requestPublisher`에서 반환된 Response에 대해
    /// HTTP 상태 코드를 검증합니다. 실패 시 AppError로 변환됩니다.
    ///
    /// - Returns: 상태 코드가 유효한 Response 또는 AppError
    func validateStatusCode() -> AnyPublisher<Response, AppError> {
        tryMap { try $0.filterSuccessfulStatusCodes() }
            .mapError { error in
                if let moyaError = error as? MoyaError {
                    return moyaError.toAppError()
                }
                return .unknown(message: error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }

    /// Response.data 추출 (상태 코드 검증 포함) + AppError 변환
    ///
    /// HTTP 상태 코드 검증 후 Response에서 Data를 추출합니다.
    /// 디코딩을 직접 제어하고 싶은 경우 `decodeResponse` 대신 사용하면 됩니다.
    ///
    /// - Returns: 유효한 Response의 Data 또는 AppError
    func mapData() -> AnyPublisher<Data, AppError> {
        tryMap { try $0.filterSuccessfulStatusCodes().data }
            .mapError { error in
                if let moyaError = error as? MoyaError {
                    return moyaError.toAppError()
                }
                return .unknown(message: error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }

    /// 전체 파이프라인: 상태 코드 검증 → 디코딩 → AppError 변환
    ///
    /// CombineMoya에서 가장 일반적인 패턴을 단일 메서드로 제공합니다.
    /// HTTP 상태 코드 검증, JSON 디코딩, 에러 변환을 모두 처리합니다.
    ///
    /// ```swift
    /// provider.requestPublisher(.fetchNotices)
    ///     .decodeResponse([NoticeDTO].self)
    ///     .sink(receiveCompletion: { ... }, receiveValue: { notices in ... })
    /// ```
    ///
    /// - Parameters:
    ///   - type: 디코딩할 타입
    ///   - decoder: JSONDecoder (기본값: JSONDecoder())
    /// - Returns: 디코딩된 객체 또는 AppError
    func decodeResponse<T: Decodable>(
        _ type: T.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) -> AnyPublisher<T, AppError> {
        tryMap { try $0.filterSuccessfulStatusCodes().data }
            .decode(type: type, decoder: decoder)
            .mapError { error in
                if let moyaError = error as? MoyaError {
                    return moyaError.toAppError()
                } else if let decodingError = error as? DecodingError {
                    return .api(.decodingFailed(detail: describeDecodingError(decodingError)))
                }
                return .unknown(message: error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - DecodingError Description

private func describeDecodingError(_ error: DecodingError) -> String {
    switch error {
    case .keyNotFound(let key, _):
        return "Missing key: \(key.stringValue)"
    case .typeMismatch(let type, let context):
        let path = context.codingPath.map(\.stringValue).joined(separator: ".")
        return "Type mismatch: expected \(type) at \(path)"
    case .valueNotFound(let type, _):
        return "Value not found: \(type)"
    case .dataCorrupted(let context):
        return "Data corrupted: \(context.debugDescription)"
    @unknown default:
        return "Unknown decoding error"
    }
}

