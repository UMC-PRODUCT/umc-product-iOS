//
//  SearchChallengerViewModelTests.swift
//  AppProductTests
//
//  Created by Codex on 3/10/26.
//

@testable import AppProduct
import Testing

struct SearchChallengerViewModelTests {

    @Test("챌린저 검색은 1초 디바운스 후 마지막 입력만 요청한다")
    func searchUsesOneSecondDebounce() async throws {
        let useCase = MockSearchChallengersUseCase()
        let viewModel = await MainActor.run {
            SearchChallengerViewModel(searchChallengersUseCase: useCase)
        }

        await MainActor.run {
            viewModel.searchText = "리"
            viewModel.scheduleSearch()
        }
        try await Task.sleep(nanoseconds: 300_000_000)

        await MainActor.run {
            viewModel.searchText = "리버"
            viewModel.scheduleSearch()
        }
        try await Task.sleep(nanoseconds: 900_000_000)

        let beforeDebounceSnapshot = await useCase.snapshot()
        #expect(beforeDebounceSnapshot.keywords.isEmpty)

        try await Task.sleep(nanoseconds: 250_000_000)

        let afterDebounceSnapshot = await useCase.snapshot()
        #expect(afterDebounceSnapshot.keywords == ["리버"])

        await MainActor.run {
            viewModel.cancelSearch()
        }
    }

    @Test("새 검색어 입력은 이미 시작된 챌린저 검색 요청을 취소하지 않는다")
    func newInputDoesNotCancelInFlightSearchRequest() async throws {
        let useCase = MockSearchChallengersUseCase(
            responseDelayNanoseconds: 400_000_000
        )
        let viewModel = await MainActor.run {
            SearchChallengerViewModel(searchChallengersUseCase: useCase)
        }

        await MainActor.run {
            viewModel.searchText = "리"
            viewModel.scheduleSearch()
        }
        try await Task.sleep(nanoseconds: 1_050_000_000)

        await MainActor.run {
            viewModel.searchText = "리버"
            viewModel.scheduleSearch()
        }
        try await Task.sleep(nanoseconds: 1_600_000_000)

        let snapshot = await useCase.snapshot()
        #expect(snapshot.keywords == ["리", "리버"])
        #expect(snapshot.cancelledCallCount == 0)

        await MainActor.run {
            viewModel.cancelSearch()
        }
    }
}

private actor MockSearchChallengersUseCase: SearchChallengersUseCaseProtocol {
    private(set) var keywords: [String] = []
    private(set) var cancelledCallCount: Int = 0

    private let responseDelayNanoseconds: UInt64

    init(responseDelayNanoseconds: UInt64 = 0) {
        self.responseDelayNanoseconds = responseDelayNanoseconds
    }

    func execute(
        query: ChallengerSearchRequestDTO
    ) async throws -> ([ChallengerInfo], hasNext: Bool, nextCursor: Int?) {
        keywords.append(query.keyword ?? "")

        if responseDelayNanoseconds > 0 {
            do {
                try await Task.sleep(nanoseconds: responseDelayNanoseconds)
            } catch {
                cancelledCallCount += 1
                throw error
            }
        }

        return (
            [ChallengerInfo.fixture(name: query.keyword ?? "")],
            false,
            nil
        )
    }

    func snapshot() -> (keywords: [String], cancelledCallCount: Int) {
        (keywords, cancelledCallCount)
    }
}

private extension ChallengerInfo {
    static func fixture(name: String) -> ChallengerInfo {
        ChallengerInfo(
            memberId: 1,
            challengerId: 1,
            gen: 11,
            name: name,
            nickname: name,
            schoolName: "UMC",
            profileImage: nil,
            part: .front(type: .ios)
        )
    }
}
