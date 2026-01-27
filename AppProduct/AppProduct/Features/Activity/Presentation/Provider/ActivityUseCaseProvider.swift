//
//  ActivityUseCaseProvider.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/25/26.
//

import Foundation

/// Activity Feature에서 사용하는 UseCase들을 제공하는 Provider Protocol
protocol ActivityUseCaseProviding {
    // MARK: - Session
    var fetchSessionsUseCase: FetchSessionsUseCaseProtocol { get }
    var fetchUserIdUseCase: FetchUserIdUseCaseProtocol { get }

    // MARK: - Attendance
    var challengerAttendanceUseCase: ChallengerAttendanceUseCaseProtocol { get }
    var operatorAttendanceUseCase: OperatorAttendanceUseCaseProtocol { get }

    // MARK: - Schedule Classifier
    var classifyScheduleUseCase: ClassifyScheduleUseCase { get }
}

/// Activity UseCase Provider 구현
///
/// RepositoryProvider와 Cross-Feature Repository를 주입받아 UseCase들을 생성합니다.
/// Activity Feature의 모든 UseCase를 중앙에서 관리합니다.
final class ActivityUseCaseProvider: ActivityUseCaseProviding {

    // MARK: - Property

    let fetchSessionsUseCase: FetchSessionsUseCaseProtocol
    let fetchUserIdUseCase: FetchUserIdUseCaseProtocol
    let challengerAttendanceUseCase: ChallengerAttendanceUseCaseProtocol
    let operatorAttendanceUseCase: OperatorAttendanceUseCaseProtocol
    let classifyScheduleUseCase: ClassifyScheduleUseCase

    // MARK: - Init

    init(
        repositoryProvider: ActivityRepositoryProviding,
        classifierRepository: ScheduleClassifierRepository
    ) {
        self.fetchSessionsUseCase = FetchSessionsUseCase(
            repository: repositoryProvider.activityRepository
        )
        self.fetchUserIdUseCase = FetchUserIdUseCase(
            repository: repositoryProvider.activityRepository
        )
        self.challengerAttendanceUseCase = ChallengerAttendanceUseCase(
            repository: repositoryProvider.attendanceRepository
        )
        self.operatorAttendanceUseCase = OperatorAttendanceUseCase(
            repository: repositoryProvider.attendanceRepository
        )
        self.classifyScheduleUseCase = ClassifyScheduleUseCaseImpl(
            repository: classifierRepository
        )
    }
}
