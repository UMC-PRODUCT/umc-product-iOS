//
//  HomeUseCaseTests.swift
//  AppProductTests
//
//  Created by euijjang97 on 2/12/26.
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
                ],
                generations: []
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
        HomeProfileResult(
            memberId: 0,
            schoolId: 0,
            seasonTypes: [],
            roles: [],
            generations: []
        )
    )

    func getMyProfile() async throws -> HomeProfileResult {
        getMyProfileCalled = true
        return try getMyProfileResult.get()
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

    // MARK: - registerFCMToken

    var registerFCMTokenCalled = false
    var registerFCMTokenChallengerId: Int?
    var registerFCMTokenValue: String?

    func registerFCMToken(challengerId: Int, fcmToken: String) async throws {
        registerFCMTokenCalled = true
        registerFCMTokenChallengerId = challengerId
        registerFCMTokenValue = fcmToken
    }

    // MARK: - searchChallengers

    func searchChallengers(
        query: ChallengerSearchRequestDTO
    ) async throws -> ChallengerSearchResponseDTO {
        fatalError("Not needed in Home tests")
    }
}
