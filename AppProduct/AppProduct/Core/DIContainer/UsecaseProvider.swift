//
//  UsecaseProvider.swift
//  AppProduct
//
//  Created by euijjang97 on 1/8/26.
//

import Foundation

/// 앱 전역에서 사용하는 UseCase Provider Protocol
///
/// 각 Feature별 Provider를 통해 UseCase에 접근합니다.
protocol UsecaseProviding {
    var activity: ActivityUseCaseProviding { get }
    var community: CommunityUseCaseProviding { get }
}

/// UseCase Provider 구현
///
/// Feature별 UseCase Provider를 통합 관리합니다.
/// Feature 간 UseCase 접근 시 사용합니다.
final class UseCaseProvider: UsecaseProviding {
    /// Activity Feature UseCase Provider
    let activity: ActivityUseCaseProviding
    let community: CommunityUseCaseProviding

    init(
        activity: ActivityUseCaseProviding,
        community: CommunityUseCaseProviding
    ) {
        self.activity = activity
        self.community = community
    }
}
