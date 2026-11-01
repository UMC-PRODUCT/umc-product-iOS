//
//  MemberReportFormViewModelTests.swift
//  CoreUIComponentsTests
//
//  Created by euijjang97 on 11/1/26.
//

import CoreDomain
import Testing
@testable import CoreUIComponents

@Suite("사용자 신고 폼")
@MainActor
struct MemberReportFormViewModelTests {
    @Test("전송 중 중복 제출을 막고 서버 완료 후에만 성공을 표시한다")
    func successAndDuplicateSubmission() async {
        let useCase = GatedReportUseCase()
        let viewModel = MemberReportFormViewModel(memberId: "12", useCase: useCase)
        viewModel.draft = MemberReportDraft(reasons: [.other], detail: "내용")
        let task = Task { await viewModel.submit() }
        await useCase.waitUntilStarted()
        #expect(viewModel.isSubmitting)
        #expect(!viewModel.didSubmit)
        #expect(!viewModel.canSubmit)
        await viewModel.submit()
        #expect(useCase.calls == 1)
        useCase.complete()
        await task.value
        #expect(viewModel.didSubmit)
        #expect(!viewModel.isSubmitting)
        #expect(useCase.memberId == "12")
    }

    @Test("전송 실패는 입력을 보존하고 오류를 표시하며 재시도를 허용한다")
    func failurePreservesDraft() async {
        let useCase = GatedReportUseCase()
        useCase.failsImmediately = true
        let viewModel = MemberReportFormViewModel(memberId: "12", useCase: useCase)
        let draft = MemberReportDraft(reasons: [.spam, .other], detail: "입력 보존")
        viewModel.draft = draft
        await viewModel.submit()
        #expect(viewModel.draft == draft)
        #expect(viewModel.failure != nil)
        #expect(!viewModel.didSubmit)
        #expect(viewModel.canSubmit)
    }
}

@MainActor
private final class GatedReportUseCase: ReportMemberUseCaseProtocol {
    var calls = 0
    var memberId: String?
    var failsImmediately = false
    private var continuation: CheckedContinuation<Void, Never>?
    private var waiter: CheckedContinuation<Void, Never>?

    func execute(memberId: String, draft: MemberReportDraft) async throws {
        self.memberId = memberId
        calls += 1
        if failsImmediately { throw MemberReportError.alreadyReported }
        await withCheckedContinuation {
            continuation = $0
            waiter?.resume()
            waiter = nil
        }
    }

    func waitUntilStarted() async {
        guard continuation == nil else { return }
        await withCheckedContinuation { waiter = $0 }
    }

    func complete() { continuation?.resume(); continuation = nil }
}
