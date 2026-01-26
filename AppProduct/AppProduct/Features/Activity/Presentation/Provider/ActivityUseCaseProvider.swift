//
//  ActivityUseCaseProvider.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/25/26.
//

import Foundation

/// Activity Feature에서 사용하는 UseCase들을 제공하는 Provider Protocol
protocol ActivityUseCaseProviding {
    var fetchSessionsUseCase: FetchSessionsUseCaseProtocol { get }
    var fetchUserIdUseCase: FetchUserIdUseCaseProtocol { get }
    var classifyScheduleUseCase: ClassifyScheduleUseCase { get }
}

/// Activity UseCase Provider 구현
///
/// Repository만 주입받아 내부에서 UseCase들을 생성합니다.
final class ActivityUseCaseProvider: ActivityUseCaseProviding {
    let fetchSessionsUseCase: FetchSessionsUseCaseProtocol
    let fetchUserIdUseCase: FetchUserIdUseCaseProtocol
    let classifyScheduleUseCase: ClassifyScheduleUseCase

    init(
        repository: ActivityRepositoryProtocol,
        classifierRepository: ScheduleClassifierRepository
    ) {
        self.fetchSessionsUseCase = FetchSessionsUseCase(repository: repository)
        self.fetchUserIdUseCase = FetchUserIdUseCase(repository: repository)
        self.classifyScheduleUseCase = ClassifyScheduleUseCaseImpl(
            repository: classifierRepository
        )
    }
}
