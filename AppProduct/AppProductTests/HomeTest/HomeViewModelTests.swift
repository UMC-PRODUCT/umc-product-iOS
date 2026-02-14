//
//  HomeViewModelTests.swift
//  AppProductTests
//
//  Created by euijjang97 on 2/12/26.
//

import Testing
import Foundation
@testable import AppProduct

// MARK: - Home ViewModel Tests

@Suite("Home ViewModel Tests")
@MainActor
struct HomeViewModelTests {

    /// 테스트용 DIContainer 생성 (Spy UseCase Provider 등록)
    private static func makeContainer(
        provider: SpyHomeUseCaseProvider
    ) -> DIContainer {
        let container = DIContainer()
        container.register(HomeUseCaseProviding.self) { provider }
        return container
    }

    // MARK: - FetchProfile

    @Suite("FetchProfile")
    @MainActor
    struct FetchProfileTests {

        @Test("fetchProfile_성공시_seasonData_loaded_roles_저장")
        func fetchProfile_성공시_seasonData_loaded_roles_저장() async {
            // Given
            let provider = SpyHomeUseCaseProvider()
            provider.stubProfileResult = .success(
                HomeProfileResult(
                    memberId: 1,
                    schoolId: 5,
                    seasonTypes: [.days(165), .gens([9, 10])],
                    roles: [
                        ChallengerRole(
                            challengerId: 100, gisu: 9, gisuId: 50,
                            roleType: .challenger, responsiblePart: nil,
                            organizationType: .school, organizationId: 5
                        ),
                        ChallengerRole(
                            challengerId: 200, gisu: 10, gisuId: 60,
                            roleType: .challenger, responsiblePart: nil,
                            organizationType: .school, organizationId: 5
                        )
                    ]
                )
            )
            let container = HomeViewModelTests.makeContainer(provider: provider)
            let sut = HomeViewModel(container: container)

            // When
            await sut.fetchProfile()

            // Then
            if case .loaded(let seasonTypes) = sut.seasonData {
                #expect(seasonTypes.count == 2)
            } else {
                Issue.record("Expected .loaded but got \(sut.seasonData)")
            }
            #expect(sut.roles.count == 2)
            #expect(sut.roles[0].challengerId == 100)
            #expect(sut.roles[1].gisuId == 60)
        }

        @Test("fetchProfile_실패시_seasonData_failed")
        func fetchProfile_실패시_seasonData_failed() async {
            // Given
            let provider = SpyHomeUseCaseProvider()
            provider.stubProfileResult = .failure(
                AppError.unknown(message: "네트워크 오류")
            )
            let container = HomeViewModelTests.makeContainer(provider: provider)
            let sut = HomeViewModel(container: container)

            // When
            await sut.fetchProfile()

            // Then
            if case .failed = sut.seasonData {
                // 성공
            } else {
                Issue.record("Expected .failed but got \(sut.seasonData)")
            }
            #expect(sut.roles.isEmpty)
        }
    }

    // MARK: - FetchPenalties

    @Suite("FetchPenalties")
    @MainActor
    struct FetchPenaltiesTests {

        @Test("fetchPenalties_roles_비어있으면_스킵")
        func fetchPenalties_roles_비어있으면_스킵() async {
            // Given
            let provider = SpyHomeUseCaseProvider()
            let container = HomeViewModelTests.makeContainer(provider: provider)
            let sut = HomeViewModel(container: container)

            // When - roles가 비어있는 상태
            await sut.fetchPenalties()

            // Then - idle 유지
            #expect(sut.generationData == .idle)
        }

        @Test("fetchPenalties_역할별_순차_호출")
        func fetchPenalties_역할별_순차_호출() async {
            // Given
            let provider = SpyHomeUseCaseProvider()
            let allPenalties = [
                GenerationData(
                    gisuId: 50, gen: 9,
                    penaltyPoint: 1,
                    penaltyLogs: [
                        PenaltyInfoItem(reason: "지각", date: "2026.03.14", penaltyPoint: 1)
                    ]
                ),
                GenerationData(
                    gisuId: 60, gen: 10,
                    penaltyPoint: 2,
                    penaltyLogs: [
                        PenaltyInfoItem(reason: "결석", date: "2026.04.01", penaltyPoint: 2)
                    ]
                )
            ]
            provider.stubPenaltyResult = .success(allPenalties)

            let container = HomeViewModelTests.makeContainer(provider: provider)
            let sut = HomeViewModel(container: container)

            // 프로필에서 roles 설정 (fetchProfile 시뮬레이션)
            provider.stubProfileResult = .success(
                HomeProfileResult(
                    memberId: 1,
                    schoolId: 5,
                    seasonTypes: [.gens([9, 10])],
                    roles: [
                        ChallengerRole(
                            challengerId: 100, gisu: 9, gisuId: 50,
                            roleType: .challenger, responsiblePart: nil,
                            organizationType: .school, organizationId: 5
                        ),
                        ChallengerRole(
                            challengerId: 200, gisu: 10, gisuId: 60,
                            roleType: .challenger, responsiblePart: nil,
                            organizationType: .school, organizationId: 5
                        )
                    ]
                )
            )
            await sut.fetchProfile()

            // When
            await sut.fetchPenalties()

            // Then
            if case .loaded(let generations) = sut.generationData {
                #expect(generations.count == 2)
                #expect(generations[0].gen == 9)
                #expect(generations[1].gen == 10)
            } else {
                Issue.record("Expected .loaded but got \(sut.generationData)")
            }

            // 각 role에 대해 호출됐는지
            #expect(provider.penaltyCallCount == 2)
            #expect(provider.penaltyCallArgs[0].challengerId == 100)
            #expect(provider.penaltyCallArgs[0].gisuId == 50)
            #expect(provider.penaltyCallArgs[1].challengerId == 200)
            #expect(provider.penaltyCallArgs[1].gisuId == 60)
        }
    }

    // MARK: - FetchRecentNotices

    @Suite("FetchRecentNotices")
    @MainActor
    struct FetchRecentNoticesTests {

        @Test("fetchRecentNotices_최신_기수_gisuId_사용")
        func fetchRecentNotices_최신_기수_gisuId_사용() async {
            // Given
            let provider = SpyHomeUseCaseProvider()
            let notices = [
                RecentNoticeData(
                    category: .oranization,
                    title: "공지 테스트",
                    createdAt: .now
                )
            ]
            provider.stubRecentNoticesResult = .success(notices)
            provider.stubProfileResult = .success(
                HomeProfileResult(
                    memberId: 1,
                    schoolId: 5,
                    seasonTypes: [.gens([9, 10])],
                    roles: [
                        ChallengerRole(
                            challengerId: 100, gisu: 9, gisuId: 50,
                            roleType: .challenger, responsiblePart: nil,
                            organizationType: .school, organizationId: 5
                        ),
                        ChallengerRole(
                            challengerId: 200, gisu: 10, gisuId: 60,
                            roleType: .challenger, responsiblePart: nil,
                            organizationType: .school, organizationId: 5
                        )
                    ]
                )
            )

            let container = HomeViewModelTests.makeContainer(provider: provider)
            let sut = HomeViewModel(container: container)
            await sut.fetchProfile()

            // When
            await sut.fetchRecentNotices()

            // Then - 최신 기수(gisu: 10)의 gisuId: 60 사용
            #expect(provider.recentNoticesGisuId == 60)

            if case .loaded(let result) = sut.recentNoticeData {
                #expect(result.count == 1)
                #expect(result[0].title == "공지 테스트")
            } else {
                Issue.record("Expected .loaded but got \(sut.recentNoticeData)")
            }
        }

        @Test("fetchRecentNotices_roles_비어있으면_스킵")
        func fetchRecentNotices_roles_비어있으면_스킵() async {
            // Given
            let provider = SpyHomeUseCaseProvider()
            let container = HomeViewModelTests.makeContainer(provider: provider)
            let sut = HomeViewModel(container: container)

            // When
            await sut.fetchRecentNotices()

            // Then
            #expect(sut.recentNoticeData == .idle)
        }
    }

    // MARK: - FetchSchedules

    @Suite("FetchSchedules")
    @MainActor
    struct FetchSchedulesTests {

        @Test("fetchSchedules_성공시_scheduleByDates_업데이트")
        func fetchSchedules_성공시_scheduleByDates_업데이트() async {
            // Given
            let provider = SpyHomeUseCaseProvider()
            let today = Calendar.current.startOfDay(for: .now)
            let schedule = ScheduleData(
                scheduleId: 1, title: "회의",
                startsAt: .now, endsAt: .now,
                status: "참여 예정", dDay: 3
            )
            provider.stubSchedulesResult = .success([today: [schedule]])

            let container = HomeViewModelTests.makeContainer(provider: provider)
            let sut = HomeViewModel(container: container)

            // When
            await sut.fetchSchedules()

            // Then
            #expect(sut.scheduleByDates.count == 1)
            #expect(sut.scheduleDates.contains(today))
        }

        @Test("fetchSchedules_실패시_빈_딕셔너리")
        func fetchSchedules_실패시_빈_딕셔너리() async {
            // Given
            let provider = SpyHomeUseCaseProvider()
            provider.stubSchedulesResult = .failure(
                AppError.unknown(message: "오류")
            )

            let container = HomeViewModelTests.makeContainer(provider: provider)
            let sut = HomeViewModel(container: container)

            // When
            await sut.fetchSchedules()

            // Then
            #expect(sut.scheduleByDates.isEmpty)
        }
    }

    // MARK: - GetSchedules

    @Suite("GetSchedules")
    @MainActor
    struct GetSchedulesTests {

        @Test("getSchedules_날짜_정규화_후_조회")
        func getSchedules_날짜_정규화_후_조회() {
            // Given
            let provider = SpyHomeUseCaseProvider()
            let container = HomeViewModelTests.makeContainer(provider: provider)
            let sut = HomeViewModel(container: container)

            let calendar = Calendar.current
            let today = calendar.startOfDay(for: .now)
            let schedule = ScheduleData(
                scheduleId: 1, title: "테스트",
                startsAt: .now, endsAt: .now,
                status: "참여 예정", dDay: 0
            )
            sut.scheduleByDates = [today: [schedule]]

            // When - 시간이 포함된 Date로 조회
            let result = sut.getSchedules(Date())

            // Then - 정규화 후 조회되어야 함
            #expect(result.count == 1)
            #expect(result[0].title == "테스트")
        }

        @Test("getSchedules_일정_없는_날짜_빈_배열")
        func getSchedules_일정_없는_날짜_빈_배열() {
            // Given
            let provider = SpyHomeUseCaseProvider()
            let container = HomeViewModelTests.makeContainer(provider: provider)
            let sut = HomeViewModel(container: container)

            // When
            let result = sut.getSchedules(Date.distantPast)

            // Then
            #expect(result.isEmpty)
        }
    }
}

// MARK: - Test Doubles

final class SpyHomeUseCaseProvider: HomeUseCaseProviding, @unchecked Sendable {

    // MARK: - Stubs

    var stubProfileResult: Result<HomeProfileResult, Error> = .success(
        HomeProfileResult(memberId: 0, schoolId: 0, seasonTypes: [], roles: [])
    )
    var stubPenaltyResult: Result<[GenerationData], Error> = .success([])
    var stubSchedulesResult: Result<[Date: [ScheduleData]], Error> = .success([:])
    var stubRecentNoticesResult: Result<[RecentNoticeData], Error> = .success([])

    // MARK: - Call Tracking

    var penaltyCallCount = 0
    var penaltyCallArgs: [(challengerId: Int, gisuId: Int)] = []
    var recentNoticesGisuId: Int?

    // MARK: - UseCase Properties

    var fetchMyProfileUseCase: FetchMyProfileUseCaseProtocol {
        StubFetchMyProfileUseCase(result: stubProfileResult)
    }

    var fetchPenaltyUseCase: FetchPenaltyUseCaseProtocol {
        StubFetchPenaltyUseCase(
            result: stubPenaltyResult,
            onExecute: { [weak self] challengerId, gisuId in
                self?.penaltyCallCount += 1
                self?.penaltyCallArgs.append((challengerId, gisuId))
            }
        )
    }

    var fetchSchedulesUseCase: FetchSchedulesUseCaseProtocol {
        StubFetchSchedulesUseCase(result: stubSchedulesResult)
    }

    var fetchRecentNoticesUseCase: FetchRecentNoticesUseCaseProtocol {
        StubFetchRecentNoticesUseCase(
            result: stubRecentNoticesResult,
            onExecute: { [weak self] query in
                self?.recentNoticesGisuId = query.gisuId
            }
        )
    }

    var generateScheduleUseCase: GenerateScheduleUseCaseProtocol {
        StubGenerateScheduleUseCase()
    }
}

// MARK: - Stub UseCases

private struct StubFetchMyProfileUseCase: FetchMyProfileUseCaseProtocol {
    let result: Result<HomeProfileResult, Error>

    func execute() async throws -> HomeProfileResult {
        try result.get()
    }
}

private final class StubFetchPenaltyUseCase:
    FetchPenaltyUseCaseProtocol, @unchecked Sendable
{
    let result: Result<[GenerationData], Error>
    let onExecute: (Int, Int) -> Void

    init(
        result: Result<[GenerationData], Error>,
        onExecute: @escaping (Int, Int) -> Void
    ) {
        self.result = result
        self.onExecute = onExecute
    }

    func execute(
        challengerId: Int, gisuId: Int
    ) async throws -> [GenerationData] {
        onExecute(challengerId, gisuId)
        return try result.get()
    }
}

private struct StubFetchSchedulesUseCase: FetchSchedulesUseCaseProtocol {
    let result: Result<[Date: [ScheduleData]], Error>

    func execute(
        year: Int, month: Int
    ) async throws -> [Date: [ScheduleData]] {
        try result.get()
    }
}

private final class StubFetchRecentNoticesUseCase:
    FetchRecentNoticesUseCaseProtocol, @unchecked Sendable
{
    let result: Result<[RecentNoticeData], Error>
    let onExecute: (NoticeListRequestDTO) -> Void

    init(
        result: Result<[RecentNoticeData], Error>,
        onExecute: @escaping (NoticeListRequestDTO) -> Void
    ) {
        self.result = result
        self.onExecute = onExecute
    }

    func execute(
        query: NoticeListRequestDTO
    ) async throws -> [RecentNoticeData] {
        onExecute(query)
        return try result.get()
    }
}

private struct StubGenerateScheduleUseCase: GenerateScheduleUseCaseProtocol {
    func execute(schedule: GenerateScheduleRequetDTO) async throws {}
}
