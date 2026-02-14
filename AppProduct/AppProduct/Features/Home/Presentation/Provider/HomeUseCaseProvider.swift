//
//  HomeUseCaseProvider.swift
//  AppProduct
//
//  Created by euijjang97 on 2/12/26.
//

import Foundation

/// Home Feature에서 사용하는 UseCase들을 제공하는 Provider Protocol
protocol HomeUseCaseProviding {
    /// 내 프로필 조회 UseCase
    var fetchMyProfileUseCase: FetchMyProfileUseCaseProtocol { get }
    /// 월별 일정 조회 UseCase
    var fetchSchedulesUseCase: FetchSchedulesUseCaseProtocol { get }
    /// 최근 공지 조회 UseCase
    var fetchRecentNoticesUseCase: FetchRecentNoticesUseCaseProtocol { get }
    /// FCM 토큰 등록 UseCase
    var registerFCMTokenUseCase: RegisterFCMTokenUseCaseProtocol { get }
    /// 일정 생성 UseCase
    var generateScheduleUseCase: GenerateScheduleUseCaseProtocol { get }
    /// 일정 수정 UseCase
    var updateScheduleUseCase: UpdateScheduleUseCaseProtocol { get }
    /// 일정 + 출석부 통합 삭제 UseCase
    var deleteScheduleUseCase: DeleteScheduleUseCaseProtocol { get }
    /// 챌린저 검색 UseCase
    var searchChallengersUseCase: SearchChallengersUseCaseProtocol { get }
}

/// Home UseCase Provider 구현
///
/// HomeRepository, ChallengerGenRepository, ScheduleRepository를
/// 주입받아 UseCase들을 생성합니다.
final class HomeUseCaseProvider: HomeUseCaseProviding {

    // MARK: - Property

    let fetchMyProfileUseCase: FetchMyProfileUseCaseProtocol
    let fetchSchedulesUseCase: FetchSchedulesUseCaseProtocol
    let fetchRecentNoticesUseCase: FetchRecentNoticesUseCaseProtocol
    let registerFCMTokenUseCase: RegisterFCMTokenUseCaseProtocol
    let generateScheduleUseCase: GenerateScheduleUseCaseProtocol
    let updateScheduleUseCase: UpdateScheduleUseCaseProtocol
    let deleteScheduleUseCase: DeleteScheduleUseCaseProtocol
    let searchChallengersUseCase: SearchChallengersUseCaseProtocol

    // MARK: - Init

    init(
        homeRepository: HomeRepositoryProtocol,
        scheduleRepository: ScheduleRepositoryProtocol,
        challengerSearchRepository: ChallengerSearchRepositoryProtocol
    ) {
        self.fetchMyProfileUseCase = FetchMyProfileUseCase(
            repository: homeRepository
        )
        self.fetchSchedulesUseCase = FetchSchedulesUseCase(
            repository: homeRepository
        )
        self.fetchRecentNoticesUseCase = FetchRecentNoticesUseCase(
            repository: homeRepository
        )
        self.registerFCMTokenUseCase = RegisterFCMTokenUseCase(
            repository: homeRepository
        )
        self.generateScheduleUseCase = GenerateScheduleUseCase(
            repository: scheduleRepository
        )
        self.updateScheduleUseCase = UpdateScheduleUseCase(
            repository: scheduleRepository
        )
        self.deleteScheduleUseCase = DeleteScheduleUseCase(
            repository: scheduleRepository
        )
        self.searchChallengersUseCase = SearchChallengersUseCase(
            repository: challengerSearchRepository
        )
    }
}
