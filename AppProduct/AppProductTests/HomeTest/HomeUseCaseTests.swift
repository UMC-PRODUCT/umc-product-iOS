//
//  HomeUseCaseTests.swift
//  AppProductTests
//
//  Created by Claude on 2/12/26.
//

import Testing
import Foundation
@testable import AppProduct

// MARK: - Home UseCase Tests

@Suite("Home UseCase Tests")
@MainActor
struct HomeUseCaseTests {

    // MARK: - FetchMyProfileUseCase

    @Suite("FetchMyProfileUseCase")
    @MainActor
    struct FetchMyProfileUseCaseTests {

        @Test("프로필_조회_성공_HomeProfileResult_반환")
        func 프로필_조회_성공_HomeProfileResult_반환() async throws {
            // Given
            let repository = SpyHomeRepository()
            let expectedResult = HomeProfileResult(
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
            repository.getMyProfileResult = .success(expectedResult)

            let sut = FetchMyProfileUseCase(repository: repository)

            // When
            let result = try await sut.execute()

            // Then
            #expect(result.seasonTypes.count == 2)
            #expect(result.roles.count == 2)
            #expect(result.roles[0].challengerId == 100)
            #expect(result.roles[1].gisuId == 60)
            #expect(repository.getMyProfileCalled)
        }

        @Test("프로필_조회_실패_에러_전파")
        func 프로필_조회_실패_에러_전파() async {
            // Given
            let repository = SpyHomeRepository()
            repository.getMyProfileResult = .failure(
                RepositoryError.serverError(code: "500", message: "서버 오류")
            )

            let sut = FetchMyProfileUseCase(repository: repository)

            // When/Then
            await #expect(throws: RepositoryError.self) {
                try await sut.execute()
            }
        }
    }

    // MARK: - FetchPenaltyUseCase

    @Suite("FetchPenaltyUseCase")
    @MainActor
    struct FetchPenaltyUseCaseTests {

        @Test("패널티_조회_저장_후_전체_반환")
        func 패널티_조회_저장_후_전체_반환() async throws {
            // Given
            let homeRepository = SpyHomeRepository()
            let genRepository = SpyGenRepository()

            let currentPenalty = GenerationData(
                gisuId: 50, gen: 9,
                penaltyPoint: 2,
                penaltyLogs: [
                    PenaltyInfoItem(reason: "지각", date: "2026.03.14", penaltyPoint: 1),
                    PenaltyInfoItem(reason: "결석", date: "2026.03.20", penaltyPoint: 1)
                ]
            )
            homeRepository.getPenaltyResult = .success(currentPenalty)

            let allPenalties = [
                currentPenalty,
                GenerationData(
                    gisuId: 60, gen: 10,
                    penaltyPoint: 1,
                    penaltyLogs: [
                        PenaltyInfoItem(reason: "지각", date: "2026.04.01", penaltyPoint: 1)
                    ]
                )
            ]
            genRepository.fetchAllPenaltiesResult = .success(allPenalties)

            let sut = FetchPenaltyUseCase(
                homeRepository: homeRepository,
                genRepository: genRepository
            )

            // When
            let result = try await sut.execute(challengerId: 100, gisuId: 50)

            // Then
            #expect(result.count == 2)
            #expect(homeRepository.getPenaltyCalled)
            #expect(homeRepository.getPenaltyChallengerId == 100)
            #expect(homeRepository.getPenaltyGisuId == 50)
            #expect(genRepository.savePenaltyCalled)
            #expect(genRepository.fetchAllPenaltiesCalled)
        }

        @Test("패널티_API_실패시_에러_전파")
        func 패널티_API_실패시_에러_전파() async {
            // Given
            let homeRepository = SpyHomeRepository()
            let genRepository = SpyGenRepository()
            homeRepository.getPenaltyResult = .failure(
                RepositoryError.serverError(code: "404", message: "챌린저를 찾을 수 없습니다")
            )

            let sut = FetchPenaltyUseCase(
                homeRepository: homeRepository,
                genRepository: genRepository
            )

            // When/Then
            await #expect(throws: RepositoryError.self) {
                try await sut.execute(challengerId: 999, gisuId: 99)
            }
            #expect(!genRepository.savePenaltyCalled)
        }
    }

    // MARK: - FetchSchedulesUseCase

    @Suite("FetchSchedulesUseCase")
    @MainActor
    struct FetchSchedulesUseCaseTests {

        @Test("일정_조회_성공")
        func 일정_조회_성공() async throws {
            // Given
            let repository = SpyHomeRepository()
            let today = Calendar.current.startOfDay(for: .now)
            let schedule = ScheduleData(
                scheduleId: 1, title: "데모데이",
                startsAt: .now, endsAt: .now,
                status: "참여 예정", dDay: 7
            )
            repository.getSchedulesResult = .success([today: [schedule]])

            let sut = FetchSchedulesUseCase(repository: repository)

            // When
            let result = try await sut.execute(year: 2026, month: 2)

            // Then
            #expect(result.count == 1)
            #expect(result[today]?.count == 1)
            #expect(result[today]?.first?.title == "데모데이")
        }
    }

    // MARK: - FetchRecentNoticesUseCase

    @Suite("FetchRecentNoticesUseCase")
    @MainActor
    struct FetchRecentNoticesUseCaseTests {

        @Test("최근_공지_조회_성공")
        func 최근_공지_조회_성공() async throws {
            // Given
            let repository = SpyHomeRepository()
            let notices = [
                RecentNoticeData(
                    category: .oranization,
                    title: "Web 파트 1회차 스터디 공지",
                    createdAt: .now
                )
            ]
            repository.getRecentNoticesResult = .success(notices)

            let sut = FetchRecentNoticesUseCase(repository: repository)

            // When
            let query = NoticeListRequestDTO(gisuId: 60, size: 5)
            let result = try await sut.execute(query: query)

            // Then
            #expect(result.count == 1)
            #expect(result[0].title == "Web 파트 1회차 스터디 공지")
            #expect(repository.getRecentNoticesQuery?.gisuId == 60)
        }
    }
}

// MARK: - Test Doubles

final class SpyHomeRepository: HomeRepositoryProtocol, @unchecked Sendable {

    // MARK: - getMyProfile

    var getMyProfileCalled = false
    var getMyProfileResult: Result<HomeProfileResult, Error> = .success(
        HomeProfileResult(memberId: 0, schoolId: 0, seasonTypes: [], roles: [])
    )

    func getMyProfile() async throws -> HomeProfileResult {
        getMyProfileCalled = true
        return try getMyProfileResult.get()
    }

    // MARK: - getPenalty

    var getPenaltyCalled = false
    var getPenaltyChallengerId: Int?
    var getPenaltyGisuId: Int?
    var getPenaltyResult: Result<GenerationData, Error> = .success(
        GenerationData(gisuId: 0, gen: 0, penaltyPoint: 0, penaltyLogs: [])
    )

    func getPenalty(challengerId: Int, gisuId: Int) async throws -> GenerationData {
        getPenaltyCalled = true
        getPenaltyChallengerId = challengerId
        getPenaltyGisuId = gisuId
        return try getPenaltyResult.get()
    }

    // MARK: - getSchedules

    var getSchedulesResult: Result<[Date: [ScheduleData]], Error> = .success([:])

    func getSchedules(year: Int, month: Int) async throws -> [Date: [ScheduleData]] {
        try getSchedulesResult.get()
    }

    // MARK: - getRecentNotices

    var getRecentNoticesQuery: NoticeListRequestDTO?
    var getRecentNoticesResult: Result<[RecentNoticeData], Error> = .success([])

    func getRecentNotices(query: NoticeListRequestDTO) async throws -> [RecentNoticeData] {
        getRecentNoticesQuery = query
        return try getRecentNoticesResult.get()
    }

    // MARK: - searchChallengers

    func searchChallengers(
        query: ChallengerSearchRequestDTO
    ) async throws -> ChallengerSearchResponseDTO {
        fatalError("Not needed in Home tests")
    }
}

final class SpyGenRepository: ChallengerGenRepositoryProtocol, @unchecked Sendable {

    var savePenaltyCalled = false
    var savedPenalty: GenerationData?
    var fetchAllPenaltiesCalled = false
    var fetchAllPenaltiesResult: Result<[GenerationData], Error> = .success([])

    func savePenalty(_ data: GenerationData) throws {
        savePenaltyCalled = true
        savedPenalty = data
    }

    func fetchAllPenalties() throws -> [GenerationData] {
        fetchAllPenaltiesCalled = true
        return try fetchAllPenaltiesResult.get()
    }

    func fetchGenGisuIdPairs() throws -> [(gen: Int, gisuId: Int)] {
        []
    }
}
