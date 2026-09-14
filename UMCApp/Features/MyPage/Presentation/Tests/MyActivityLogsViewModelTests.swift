//
//  MyActivityLogsViewModelTests.swift
//  MyPagePresentationTests
//
//  Created by euijjang97 on 9/14/26.
//

import Testing
import Foundation
import UMCFoundation
import CoreDomain
import MyPageDomain
@testable import MyPagePresentation

@MainActor
@Suite("MyActivityLogsViewModel — 기록 추가 / 중복 호출 가드 / 실패 전파")
struct MyActivityLogsViewModelTests {

    @Test("addRecord 성공 — 코드 전달 + 재조회 결과로 목록 갱신 + 성공 플래그 노출")
    func addRecordSuccessRefreshesLogs() async throws {
        let refreshed = makeStubActivityLog(generation: 12)
        let mock = MockMyPageRepository()
        mock.fetchMyProfileResult = .success(makeStubProfileData(activityLogs: [refreshed]))
        let viewModel = makeViewModel(activityLogs: [], repository: mock)

        try await viewModel.addRecord(code: "ABC123")

        #expect(mock.addChallengerRecordCallCount == 1)
        #expect(mock.addChallengerRecordReceivedCode == "ABC123")
        // 캐시 무효화는 Repository 몫이라 화면은 기본(캐시) 경로로 읽는다.
        #expect(mock.fetchMyProfileCallCount == 1)
        #expect(mock.fetchMyProfileReceivedForceRefresh == false)
        #expect(viewModel.activityLogs == [refreshed])
        #expect(viewModel.didRecentlyAdd == true)
        #expect(viewModel.isAdding == false)
    }

    @Test("추가 진행 중 들어온 중복 호출은 무시")
    func duplicateAddIgnoredWhileAdding() async throws {
        let mock = MockMyPageRepository()
        mock.fetchMyProfileResult = .success(makeStubProfileData())
        let viewModel = makeViewModel(activityLogs: [], repository: mock)
        // 요청이 떠 있는 동안(= isAdding == true) 재진입시켜 가드를 확인한다.
        mock.onAddChallengerRecord = { [weak viewModel] in
            try? await viewModel?.addRecord(code: "SECOND")
        }

        try await viewModel.addRecord(code: "FIRST")

        #expect(mock.addChallengerRecordCallCount == 1)
        #expect(mock.addChallengerRecordReceivedCode == "FIRST")
        #expect(mock.fetchMyProfileCallCount == 1)
    }

    @Test("추가 실패 — 에러 전파 + 목록 미갱신 + 플래그 복구")
    func addRecordFailurePropagates() async {
        let existing = makeStubActivityLog(generation: 11)
        let mock = MockMyPageRepository()
        mock.addChallengerRecordError = MyPageTestError.boom
        let viewModel = makeViewModel(activityLogs: [existing], repository: mock)

        await #expect(throws: MyPageTestError.boom) {
            try await viewModel.addRecord(code: "ABC123")
        }

        #expect(mock.addChallengerRecordCallCount == 1)
        #expect(mock.fetchMyProfileCallCount == 0)
        #expect(viewModel.activityLogs == [existing])
        #expect(viewModel.didRecentlyAdd == false)
        #expect(viewModel.isAdding == false)
    }
}

// MARK: - Helpers

@MainActor
private func makeViewModel(
    activityLogs: [ActivityLog],
    repository: MockMyPageRepository = MockMyPageRepository()
) -> MyActivityLogsViewModel {
    MyActivityLogsViewModel(
        activityLogs: activityLogs,
        useCaseProvider: makeUseCaseProvider(repository)
    )
}

private func makeStubActivityLog(generation: Int) -> ActivityLog {
    ActivityLog(part: .pm, generation: generation, role: .challenger)
}
