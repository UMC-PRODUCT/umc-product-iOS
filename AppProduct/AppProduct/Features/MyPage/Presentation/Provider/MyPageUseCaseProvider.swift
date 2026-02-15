//
//  MyPageUseCaseProvider.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

/// MyPage Feature의 UseCase들을 제공하는 Protocol
///
/// ViewModel에서 여러 UseCase를 개별 주입하는 대신,
/// Provider를 통해 관련 UseCase를 묶어서 제공합니다.
protocol MyPageUseCaseProviding {
    var fetchMyPageProfileUseCase: FetchMyPageProfileUseCaseProtocol { get }
    var updateMyPageProfileImageUseCase: UpdateMyPageProfileImageUseCaseProtocol { get }
    var deleteMemberUseCase: DeleteMemberUseCaseProtocol { get }
    var fetchMyPostsUseCase: FetchMyPostsUseCaseProtocol { get }
    var fetchMyCommentedPostsUseCase: FetchMyCommentedPostsUseCaseProtocol { get }
    var fetchMyScrappedPostsUseCase: FetchMyScrappedPostsUseCaseProtocol { get }
    /// 약관 조회 UseCase
    var fetchTermsUseCase: FetchTermsUseCaseProtocol { get }
}

/// MyPage UseCase Provider 구현체
///
/// 단일 Repository를 주입받아 모든 UseCase를 초기화합니다.
final class MyPageUseCaseProvider: MyPageUseCaseProviding {
    // MARK: - Property

    let fetchMyPageProfileUseCase: FetchMyPageProfileUseCaseProtocol
    let updateMyPageProfileImageUseCase: UpdateMyPageProfileImageUseCaseProtocol
    let deleteMemberUseCase: DeleteMemberUseCaseProtocol
    let fetchMyPostsUseCase: FetchMyPostsUseCaseProtocol
    let fetchMyCommentedPostsUseCase: FetchMyCommentedPostsUseCaseProtocol
    let fetchMyScrappedPostsUseCase: FetchMyScrappedPostsUseCaseProtocol
    /// 약관 조회 UseCase
    let fetchTermsUseCase: FetchTermsUseCaseProtocol

    // MARK: - Init

    init(repository: MyPageRepositoryProtocol) {
        self.fetchMyPageProfileUseCase = FetchMyPageProfileUseCase(
            repository: repository
        )
        self.updateMyPageProfileImageUseCase = UpdateMyPageProfileImageUseCase(
            repository: repository
        )
        self.deleteMemberUseCase = DeleteMemberUseCase(
            repository: repository
        )
        self.fetchMyPostsUseCase = FetchMyPostsUseCase(
            repository: repository
        )
        self.fetchMyCommentedPostsUseCase = FetchMyCommentedPostsUseCase(
            repository: repository
        )
        self.fetchMyScrappedPostsUseCase = FetchMyScrappedPostsUseCase(
            repository: repository
        )
        self.fetchTermsUseCase = FetchTermsUseCase(
            repository: repository
        )
    }
}
