//
//  Loadable.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/7/25.
//

import Foundation

/// 비동기 데이터 로딩 상태
/// - ViewModel에서 데이터 상태를 관리할 때 사용
enum Loadable<T: Equatable>: Equatable {
    /// 초기 상태 (로딩 전)
    case idle

    /// 로딩 중
    case loading

    /// 로딩 성공
    case loaded(T)

    /// 로딩 실패
    case failed(AppError)

    // MARK: - Computed Property

    /// 로드된 값 (있는 경우)
    var value: T? {
        if case .loaded(let value) = self {
            return value
        }
        return nil
    }

    /// 에러 (있는 경우)
    var error: AppError? {
        if case .failed(let error) = self {
            return error
        }
        return nil
    }

    /// 로딩 중 여부
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    /// 로드 완료 여부 (성공 또는 실패)
    var isComplete: Bool {
        switch self {
        case .loaded, .failed:
            return true
        default:
            return false
        }
    }

    /// 아이들 상태 여부
    var isIdle: Bool {
        if case .idle = self {
            return true
        }
        return false
    }

    // MARK: - Mapping

    /// 값 변환
    func map<U: Equatable>(_ transform: (T) -> U) -> Loadable<U> {
        switch self {
        case .idle:
            return .idle
        case .loading:
            return .loading
        case .loaded(let value):
            return .loaded(transform(value))
        case .failed(let error):
            return .failed(error)
        }
    }
}
