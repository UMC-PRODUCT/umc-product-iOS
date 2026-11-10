//
//  ProjectApplicationFlowViewModelTests.swift
//  ProjectPresentationTests
//
//  Created by euijjang97 on 9/20/26.
//

import Foundation
import ProjectDomain
import Testing
import UMCFoundation
@testable import ProjectPresentation

@MainActor
@Suite("프로젝트 지원·심사 화면 상태")
struct ProjectApplicationFlowViewModelTests {

    @Test("탐색 목록은 현재 기수와 진행 중 상태로 요청한다")
    func browseRequestsInProgressProjects() async {
        let projectUseCase = ProjectUseCaseSpy()
        projectUseCase.projectPage = Self.projectPage
        let viewModel = ProjectBrowseViewModel(
            projectUseCase: projectUseCase,
            gisuId: "14"
        )

        await viewModel.fetch()

        #expect(projectUseCase.receivedSearchQueries == [
            ProjectSearchQuery(gisuId: "14", statuses: [.inProgress])
        ])
        #expect(viewModel.projects.value?.map(\.id) == ["101"])
    }

    @Test("지원서 임시 저장은 초안을 만든 뒤 답변을 저장한다")
    func firstSaveCreatesDraftThenUpdatesAnswers() async throws {
        let applicationUseCase = ProjectApplicationUseCaseSpy()
        applicationUseCase.form = Self.applicationForm
        applicationUseCase.createdResult = .init(applicationId: "301", status: .draft)
        applicationUseCase.updatedResult = .init(applicationId: "301", status: .draft)
        let matchingRoundUseCase = ProjectMatchingRoundUseCaseSpy()
        matchingRoundUseCase.rounds = [Self.matchingRound]
        let viewModel = ProjectApplicationEditorViewModel(
            projectId: "101",
            applicationId: nil,
            applicationUseCase: applicationUseCase,
            matchingRoundUseCase: matchingRoundUseCase,
            chapterId: "9"
        )
        await viewModel.fetch()
        viewModel.updateText(questionId: "401", text: "지원 동기")

        try await viewModel.save()

        #expect(applicationUseCase.createdApplications.count == 1)
        #expect(applicationUseCase.createdApplications.first?.projectId == "101")
        #expect(applicationUseCase.createdApplications.first?.matchingRoundId == "201")
        #expect(applicationUseCase.updatedApplications.count == 1)
        #expect(applicationUseCase.updatedApplications.first?.applicationId == "301")
        #expect(applicationUseCase.updatedApplications.first?.answers == [
            ProjectAnswerInput(questionId: "401", textValue: "지원 동기")
        ])
        #expect(viewModel.applicationId == "301")
    }

    @Test("지원서 제출은 저장 뒤 제출 상태를 반영한다")
    func submitSavesThenSubmits() async throws {
        let applicationUseCase = ProjectApplicationUseCaseSpy()
        applicationUseCase.form = Self.applicationForm
        applicationUseCase.detail = Self.draftApplicationDetail
        applicationUseCase.updatedResult = .init(applicationId: "301", status: .draft)
        applicationUseCase.submittedResult = .init(applicationId: "301", status: .submitted)
        let viewModel = ProjectApplicationEditorViewModel(
            projectId: "101",
            applicationId: "301",
            applicationUseCase: applicationUseCase,
            matchingRoundUseCase: ProjectMatchingRoundUseCaseSpy(),
            chapterId: nil
        )
        await viewModel.fetch()
        viewModel.updateText(questionId: "401", text: "지원 동기")

        try await viewModel.submit()

        #expect(applicationUseCase.submittedApplications.count == 1)
        #expect(applicationUseCase.submittedApplications.first?.projectId == "101")
        #expect(applicationUseCase.submittedApplications.first?.applicationId == "301")
        #expect(viewModel.status == .submitted)
    }

    @Test("기존 지원서는 상세의 질문 스냅샷을 사용한다")
    func existingApplicationUsesDetailSnapshot() async {
        let applicationUseCase = ProjectApplicationUseCaseSpy()
        applicationUseCase.detail = Self.draftApplicationDetail
        let viewModel = ProjectApplicationEditorViewModel(
            projectId: "101",
            applicationId: "301",
            applicationUseCase: applicationUseCase,
            matchingRoundUseCase: ProjectMatchingRoundUseCaseSpy(),
            chapterId: nil
        )

        await viewModel.fetch()

        #expect(applicationUseCase.fetchApplicationFormCallCount == 0)
        #expect(applicationUseCase.fetchApplicationCallCount == 1)
        #expect(
            viewModel.form.value?.sections.flatMap(\.questions).map(\.questionId) == ["401"]
        )
    }

    @Test("상세 표시 상태가 nil이면 제출 폼 응답 상태로 편집을 차단한다")
    func hiddenDecisionStatusUsesSubmittedFormResponseStatus() async {
        let applicationUseCase = ProjectApplicationUseCaseSpy()
        applicationUseCase.detail = Self.hiddenDecisionApplicationDetail
        let viewModel = ProjectApplicationEditorViewModel(
            projectId: "101",
            applicationId: "301",
            applicationUseCase: applicationUseCase,
            matchingRoundUseCase: ProjectMatchingRoundUseCaseSpy(),
            chapterId: nil
        )

        await viewModel.fetch()

        #expect(viewModel.status == .submitted)
        #expect(viewModel.canEdit == false)
        #expect(viewModel.canSave == false)
    }

    @Test("제출본은 같은 차수의 시작과 종료 시각을 포함한 기간에만 수정한다")
    func submittedEditingUsesAppliedRoundWindow() async {
        for timestamp in [-1.0, 0, 50, 100, 101] {
            let (viewModel, _, _) = submittedEditor(time: timestamp)
            await viewModel.fetch()
            #expect(viewModel.canEdit == (0...100).contains(timestamp))
        }
    }

    @Test("다른 차수가 열려 있어도 해당 지원서의 차수가 없으면 수정하지 않는다")
    func unrelatedRoundDoesNotEnableEditing() async {
        let (viewModel, application, _) = submittedEditor(time: 50)
        application.detail = ProjectApplicationDetail(
            applicationId: "301", applicant: Self.applicant,
            matchingRound: .init(id: "202", type: .planDeveloper, phase: .second),
            status: nil, submittedAt: nil, statusChangedAt: nil,
            formResponse: Self.formResponse(status: .submitted)
        )
        await viewModel.fetch()
        viewModel.selectedMatchingRoundId = "other-round"
        #expect(!viewModel.canSave)
    }

    @Test("수정 저장은 전체 답변을 PUT하고 재제출하지 않는다")
    func submittedSaveOnlyUpdatesAnswers() async throws {
        let (viewModel, application, _) = submittedEditor(time: 50)
        await viewModel.fetch()
        viewModel.updateText(questionId: "401", text: "수정한 지원 동기")
        try await viewModel.save()
        #expect(application.updatedApplications.first?.answers == [
            ProjectAnswerInput(questionId: "401", textValue: "수정한 지원 동기")
        ])
        #expect(application.createdApplications.isEmpty)
        #expect(application.submittedApplications.isEmpty)
        #expect(viewModel.status == .submitted)
        await #expect(throws: AppError.self) { try await viewModel.submit() }
        #expect(application.updatedApplications.count == 1)
    }

    @Test("제출본 필수 답변 누락은 요청 전에 차단한다")
    func submittedSaveValidatesRequiredAnswers() async {
        let (viewModel, application, _) = submittedEditor(time: 50)
        await viewModel.fetch()
        viewModel.updateText(questionId: "401", text: "  ")
        await #expect(throws: AppError.self) { try await viewModel.save() }
        #expect(application.updatedApplications.isEmpty)
    }

    @Test("화면을 연 뒤 기간이 종료되면 저장하지 않는다")
    func expirationBeforeSaveBlocksRequest() async {
        var currentTime = Date(timeIntervalSince1970: 50)
        let application = ProjectApplicationUseCaseSpy()
        application.detail = Self.hiddenDecisionApplicationDetail
        let rounds = ProjectMatchingRoundUseCaseSpy()
        rounds.rounds = [Self.matchingRound]
        let viewModel = ProjectApplicationEditorViewModel(
            projectId: "101", applicationId: "301", applicationUseCase: application,
            matchingRoundUseCase: rounds, chapterId: nil, now: { currentTime }
        )
        await viewModel.fetch()
        currentTime = Date(timeIntervalSince1970: 101)
        await #expect(throws: AppError.self) { try await viewModel.save() }
        #expect(application.updatedApplications.isEmpty)
    }

    @Test("판정 또는 철회 상태는 기간 내에도 수정할 수 없다")
    func terminalStatesRemainReadOnly() async {
        for status in [ProjectApplicationStatus.approved, .rejected, .cancelled] {
            let (viewModel, application, _) = submittedEditor(time: 50)
            application.detail = ProjectApplicationDetail(
                applicationId: "301", applicant: Self.applicant,
                matchingRound: .init(id: "201", type: .planDeveloper, phase: .first),
                status: status, submittedAt: nil, statusChangedAt: nil,
                formResponse: Self.formResponse(status: .submitted)
            )
            await viewModel.fetch()
            #expect(!viewModel.canEdit)
        }
    }

    @Test("기간 조회 실패 후 다시 확인하면 입력을 보존하고 수정을 허용한다")
    func failedPeriodLookupCanRetryWithoutLosingAnswers() async {
        let (viewModel, _, rounds) = submittedEditor(time: 50)
        rounds.fetchError = TestError.unused
        await viewModel.fetch()
        #expect(!viewModel.canEdit)
        #expect(viewModel.form.value != nil)
        viewModel.updateText(questionId: "401", text: "보존할 답변")
        rounds.fetchError = nil
        await viewModel.fetchEditingRounds()
        #expect(viewModel.canEdit)
        #expect(viewModel.answers["401"]?.text == "보존할 답변")
    }

    @Test("서버가 기간 종료를 반환하면 답변을 보존하고 후속 수정을 막는다")
    func serverClosedRoundPreservesAnswers() async {
        let (viewModel, application, _) = submittedEditor(time: 50)
        await viewModel.fetch()
        viewModel.updateText(questionId: "401", text: "보존할 답변")
        application.updateError = AppError.network(.requestFailed(
            statusCode: 400, data: Data(#"{"code":"PROJECT-0208"}"#.utf8)
        ))
        await #expect(throws: AppError.self) { try await viewModel.save() }
        #expect(!viewModel.canEdit)
        #expect(viewModel.answers["401"]?.text == "보존할 답변")
        #expect(application.submittedApplications.isEmpty)
    }

    private func submittedEditor(time: TimeInterval) -> (
        ProjectApplicationEditorViewModel,
        ProjectApplicationUseCaseSpy,
        ProjectMatchingRoundUseCaseSpy
    ) {
        let application = ProjectApplicationUseCaseSpy()
        application.detail = Self.hiddenDecisionApplicationDetail
        application.updatedResult = .init(applicationId: "301", status: .submitted)
        let rounds = ProjectMatchingRoundUseCaseSpy()
        rounds.rounds = [Self.matchingRound]
        let viewModel = ProjectApplicationEditorViewModel(
            projectId: "101", applicationId: "301", applicationUseCase: application,
            matchingRoundUseCase: rounds, chapterId: nil,
            now: { Date(timeIntervalSince1970: time) }
        )
        return (viewModel, application, rounds)
    }

    @Test("파일·일정 질문은 잘못된 textValue 저장 요청을 만들지 않는다")
    func unsupportedAnswerTypesBlockSaving() async {
        for questionType in [ProjectQuestionType.file, .schedule] {
            let applicationUseCase = ProjectApplicationUseCaseSpy()
            applicationUseCase.form = Self.applicationForm(questionType: questionType)
            let matchingRoundUseCase = ProjectMatchingRoundUseCaseSpy()
            matchingRoundUseCase.rounds = [Self.matchingRound]
            let viewModel = ProjectApplicationEditorViewModel(
                projectId: "101",
                applicationId: nil,
                applicationUseCase: applicationUseCase,
                matchingRoundUseCase: matchingRoundUseCase,
                chapterId: "9"
            )
            await viewModel.fetch()
            viewModel.updateText(questionId: "401", text: "잘못된 문자열 답변")

            await #expect(throws: AppError.self) {
                try await viewModel.save()
            }
            await #expect(throws: AppError.self) {
                try await viewModel.submit()
            }

            #expect(viewModel.canSave == false)
            #expect(applicationUseCase.createdApplications.isEmpty)
            #expect(applicationUseCase.updatedApplications.isEmpty)
        }
    }

    @Test("지원 철회 결과가 취소 상태로 전환된다")
    func cancellationUpdatesStatus() async throws {
        let applicationUseCase = ProjectApplicationUseCaseSpy()
        applicationUseCase.detail = Self.draftApplicationDetail
        applicationUseCase.cancelledResult = .init(applicationId: "301", status: .cancelled)
        let viewModel = ProjectApplicationEditorViewModel(
            projectId: "101",
            applicationId: "301",
            applicationUseCase: applicationUseCase,
            matchingRoundUseCase: ProjectMatchingRoundUseCaseSpy(),
            chapterId: nil
        )
        await viewModel.fetch()

        try await viewModel.cancel(reason: "다른 프로젝트 지원")

        #expect(applicationUseCase.cancelledApplications.count == 1)
        #expect(applicationUseCase.cancelledApplications.first?.projectId == "101")
        #expect(applicationUseCase.cancelledApplications.first?.applicationId == "301")
        #expect(
            applicationUseCase.cancelledApplications.first?.reason == "다른 프로젝트 지원"
        )
        #expect(viewModel.status == .cancelled)
    }

    @Test("단일 프로젝트 지원자 목록은 프로젝트 전용 조회를 사용한다")
    func applicantListUsesSingleProjectEndpoint() async {
        let applicationUseCase = ProjectApplicationUseCaseSpy()
        applicationUseCase.applications = [Self.applicationSummary]
        let viewModel = ProjectApplicantsViewModel(
            projectId: "101",
            applicationUseCase: applicationUseCase
        )

        await viewModel.fetch()

        #expect(applicationUseCase.singleApplicationQueries.map(\.projectId) == ["101"])
        #expect(viewModel.applications.value?.map(\.applicationId) == ["301"])
    }

    @Test("지원자함은 여러 프로젝트 지원자를 일괄 조회한다")
    func inboxUsesBatchEndpoint() async {
        let applicationUseCase = ProjectApplicationUseCaseSpy()
        applicationUseCase.applicationsByProject = ["101": [Self.applicationSummary]]
        let viewModel = ProjectApplicationInboxViewModel(
            projectIds: ["101", "102"],
            applicationUseCase: applicationUseCase
        )

        await viewModel.fetch()

        #expect(applicationUseCase.batchApplicationQueries.map(\.projectIds) == [["101", "102"]])
        #expect(viewModel.sections.value?.first?.projectId == "101")
    }

    @Test("합격 결정 결과가 상세 상태에 반영된다")
    func approvingApplicationUpdatesDetailStatus() async throws {
        let applicationUseCase = ProjectApplicationUseCaseSpy()
        applicationUseCase.detail = Self.applicationDetail
        applicationUseCase.decisionResult = .init(applicationId: "301", status: .approved)
        let viewModel = ProjectApplicationReviewViewModel(
            projectId: "101",
            applicationId: "301",
            canDecide: true,
            applicationUseCase: applicationUseCase
        )
        await viewModel.fetch()

        try await viewModel.decide(.approved, reason: nil)

        #expect(applicationUseCase.decisions.count == 1)
        #expect(viewModel.application.value?.status == .approved)
    }
}

private extension ProjectApplicationFlowViewModelTests {
    static let summary = ProjectSummary(
        id: "101",
        name: "UMC 프로젝트",
        description: "설명",
        thumbnailImageURL: nil,
        status: .inProgress,
        productOwner: nil,
        partQuotas: [],
        partQuotaStatus: .recruiting
    )

    static let projectPage = ProjectPage(
        items: [summary],
        page: "0",
        size: "20",
        totalElements: "1",
        totalPages: "1",
        hasNext: false,
        hasPrevious: false
    )

    static let applicationForm = ProjectApplicationForm(
        projectId: "101",
        applicationFormId: "501",
        title: "지원서",
        description: nil,
        sections: [
            ProjectFormSection(
                sectionId: "1",
                type: .common,
                allowedParts: [],
                title: "공통 질문",
                description: nil,
                orderNo: "1",
                questions: [
                    ProjectFormQuestion(
                        questionId: "401",
                        type: .longText,
                        title: "지원 동기",
                        description: nil,
                        isRequired: true,
                        orderNo: "1",
                        options: []
                    )
                ]
            )
        ]
    )

    static func applicationForm(
        questionType: ProjectQuestionType
    ) -> ProjectApplicationForm {
        ProjectApplicationForm(
            projectId: "101",
            applicationFormId: "501",
            title: "지원서",
            description: nil,
            sections: [applicationSection(questionType: questionType)]
        )
    }

    static func applicationSection(
        questionType: ProjectQuestionType = .longText
    ) -> ProjectFormSection {
        ProjectFormSection(
            sectionId: "1",
            type: .common,
            allowedParts: [],
            title: "지원 당시 공통 질문",
            description: nil,
            orderNo: "1",
            questions: [
                ProjectFormQuestion(
                    questionId: "401",
                    type: questionType,
                    title: "지원 동기",
                    description: nil,
                    isRequired: true,
                    orderNo: "1",
                    options: []
                )
            ]
        )
    }

    static func formResponse(
        status: ProjectFormResponseStatus
    ) -> ProjectFormResponse {
        ProjectFormResponse(
            formResponseId: "601",
            formId: "501",
            status: status,
            submittedAt: status == .submitted ? Date(timeIntervalSince1970: 100) : nil,
            lastSavedAt: Date(timeIntervalSince1970: 50),
            sections: [applicationSection()]
        )
    }

    static let matchingRound = ProjectMatchingRound(
        id: "201",
        name: "1차 매칭",
        description: nil,
        type: .planDeveloper,
        phase: .first,
        chapterId: "9",
        startsAt: Date(timeIntervalSince1970: 0),
        endsAt: Date(timeIntervalSince1970: 100),
        decisionDeadline: Date(timeIntervalSince1970: 200),
        autoDecisionExecutedAt: nil,
        autoDecisionExecutedMemberId: nil,
        createdAt: nil,
        updatedAt: nil
    )

    static let applicant = ProjectApplicant(
        memberId: "7",
        nickname: "지원자",
        name: "홍길동",
        schoolName: "UMC대학교",
        part: .front(type: .ios)
    )

    static let applicationSummary = ProjectApplicationSummary(
        applicationId: "301",
        applicant: applicant,
        matchingRound: .init(id: "201", type: .planDeveloper, phase: .first),
        status: .submitted,
        submittedAt: nil,
        statusChangedAt: nil
    )

    static let applicationDetail = ProjectApplicationDetail(
        applicationId: "301",
        applicant: applicant,
        matchingRound: .init(id: "201", type: .planDeveloper, phase: .first),
        status: .submitted,
        submittedAt: nil,
        statusChangedAt: nil,
        formResponse: nil
    )

    static let draftApplicationDetail = ProjectApplicationDetail(
        applicationId: "301",
        applicant: applicant,
        matchingRound: .init(id: "201", type: .planDeveloper, phase: .first),
        status: .draft,
        submittedAt: nil,
        statusChangedAt: nil,
        formResponse: formResponse(status: .draft)
    )

    static let hiddenDecisionApplicationDetail = ProjectApplicationDetail(
        applicationId: "301",
        applicant: applicant,
        matchingRound: .init(id: "201", type: .planDeveloper, phase: .first),
        status: nil,
        submittedAt: Date(timeIntervalSince1970: 100),
        statusChangedAt: nil,
        formResponse: formResponse(status: .submitted)
    )
}

private final class ProjectUseCaseSpy: ProjectUseCaseProtocol, @unchecked Sendable {
    var projectPage = ProjectPage<ProjectSummary>(
        items: [], page: "0", size: "20", totalElements: "0", totalPages: "0",
        hasNext: false, hasPrevious: false
    )
    var receivedSearchQueries: [ProjectSearchQuery] = []

    func fetchProjects(query: ProjectSearchQuery) async throws -> ProjectPage<ProjectSummary> {
        receivedSearchQueries.append(query)
        return projectPage
    }

    func fetchProject(projectId: String) async throws -> ProjectDetail { throw TestError.unused }
    func fetchMembers(projectId: String) async throws -> ProjectMembers { throw TestError.unused }
    func fetchMembers(projectIds: [String]) async throws -> [String: ProjectMembers] { [:] }
    func fetchManagedProjects(gisuId: String, keyword: String?, page: Int, size: Int) async throws
        -> ProjectPage<ProjectSummary> { projectPage }
    func fetchDraftProject(gisuId: String) async throws -> ProjectDetail? { nil }
    func createDraftProject(gisuId: String, productOwnerMemberId: String?) async throws
        -> ProjectStatusResult { throw TestError.unused }
    func updateProject(projectId: String, update: ProjectInfoUpdate) async throws
        -> ProjectStatusResult { throw TestError.unused }
    func submitProject(projectId: String) async throws -> ProjectStatusResult {
        throw TestError.unused
    }
    func transferOwnership(
        projectId: String,
        newOwnerMemberId: String,
        reason: String?
    ) async throws
        -> ProjectStatusResult { throw TestError.unused }
    func addMember(projectId: String, memberId: String, part: UMCPartType) async throws -> String {
        throw TestError.unused
    }
    func removeMember(projectId: String, memberId: String, reason: String?) async throws {}
    func changeMemberStatus(projectId: String, memberId: String, status: ProjectMemberStatus,
                            reason: String) async throws {}
    func deleteProject(projectId: String) async throws {}
    func uploadImage(jpegData: Data, category: StorageFileCategory) async throws -> String {
        throw TestError.unused
    }
    func publishProject(projectId: String) async throws -> ProjectStatusResult {
        throw TestError.unused
    }
    func updatePartQuotas(projectId: String, entries: [ProjectPartQuotaEntry]) async throws {}
    func abortProject(projectId: String, reason: String) async throws {}
    func completeProjects(projectIds: [String]) async throws {}
    func fetchPermissions(projectIds: [String]) async throws -> [ProjectPermission] { [] }
    func fetchStatistics(projectIds: [String]) async throws -> ProjectChapterStatistics {
        throw TestError.unused
    }
    func fetchStatistics(chapterId: String) async throws -> ProjectChapterStatistics {
        throw TestError.unused
    }
    func fetchMatchingStatistics(chapterId: String) async throws
        -> ProjectChapterMatchingStatistics { throw TestError.unused }
}

private final class ProjectApplicationUseCaseSpy:
    ProjectApplicationUseCaseProtocol,
    @unchecked Sendable {

    struct UpdateCall { let applicationId: String; let answers: [ProjectAnswerInput] }
    struct CreateCall { let projectId: String; let matchingRoundId: String }
    struct SubmitCall { let projectId: String; let applicationId: String }
    struct SingleQuery { let projectId: String }
    struct BatchQuery { let projectIds: [String] }
    struct CancelCall {
        let projectId: String
        let applicationId: String
        let reason: String?
    }

    var form: ProjectApplicationForm?
    var detail: ProjectApplicationDetail?
    var applications: [ProjectApplicationSummary] = []
    var applicationsByProject: [String: [ProjectApplicationSummary]] = [:]
    var createdResult = ProjectApplicationResult(applicationId: "301", status: .draft)
    var updatedResult = ProjectApplicationResult(applicationId: "301", status: .draft)
    var submittedResult = ProjectApplicationResult(applicationId: "301", status: .submitted)
    var cancelledResult = ProjectApplicationResult(applicationId: "301", status: .cancelled)
    var decisionResult = ProjectApplicationResult(applicationId: "301", status: .approved)
    var createdApplications: [CreateCall] = []
    var updatedApplications: [UpdateCall] = []
    var updateError: Error?
    var submittedApplications: [SubmitCall] = []
    var cancelledApplications: [CancelCall] = []
    var singleApplicationQueries: [SingleQuery] = []
    var batchApplicationQueries: [BatchQuery] = []
    var decisions: [ProjectApplicationDecision] = []
    var fetchApplicationFormCallCount = 0
    var fetchApplicationCallCount = 0

    func fetchApplicationForm(projectId: String) async throws -> ProjectApplicationForm? {
        fetchApplicationFormCallCount += 1
        return form
    }
    func saveApplicationForm(projectId: String, title: String?, description: String?,
                             sections: [ProjectFormSection]) async throws
        -> ProjectApplicationForm { throw TestError.unused }
    func createApplication(projectId: String, matchingRoundId: String) async throws
        -> ProjectApplicationResult {
        createdApplications.append(.init(
            projectId: projectId,
            matchingRoundId: matchingRoundId
        ))
        return createdResult
    }
    func updateAnswers(projectId: String, applicationId: String,
                       answers: [ProjectAnswerInput]) async throws -> ProjectApplicationResult {
        updatedApplications.append(.init(applicationId: applicationId, answers: answers))
        if let updateError { throw updateError }
        return updatedResult
    }
    func submitApplication(projectId: String, applicationId: String) async throws
        -> ProjectApplicationResult {
        submittedApplications.append(.init(
            projectId: projectId,
            applicationId: applicationId
        ))
        return submittedResult
    }
    func cancelApplication(projectId: String, applicationId: String, reason: String?) async throws
        -> ProjectApplicationResult {
        cancelledApplications.append(.init(
            projectId: projectId,
            applicationId: applicationId,
            reason: reason
        ))
        return cancelledResult
    }
    func decideApplication(projectId: String, applicationId: String,
                           decision: ProjectApplicationDecision, reason: String?) async throws
        -> ProjectApplicationResult {
        decisions.append(decision)
        return decisionResult
    }
    func fetchMyApplications(gisuId: String, status: ProjectApplicationStatus?) async throws
        -> [MyProjectApplication] { [] }
    func fetchApplications(projectIds: [String], filter: ProjectApplicationFilter) async throws
        -> [String: [ProjectApplicationSummary]] {
        batchApplicationQueries.append(.init(projectIds: projectIds))
        return applicationsByProject
    }
    func fetchApplications(projectId: String, filter: ProjectApplicationFilter) async throws
        -> [ProjectApplicationSummary] {
        singleApplicationQueries.append(.init(projectId: projectId))
        return applications
    }
    func fetchApplication(projectId: String, applicationId: String) async throws
        -> ProjectApplicationDetail {
        fetchApplicationCallCount += 1
        guard let detail else { throw TestError.unused }
        return detail
    }
}

private final class ProjectMatchingRoundUseCaseSpy:
    ProjectMatchingRoundUseCaseProtocol,
    @unchecked Sendable {

    var rounds: [ProjectMatchingRound] = []
    var fetchError: Error?

    func fetchMatchingRounds(chapterId: String?, time: Date?) async throws
        -> [ProjectMatchingRound] {
        if let fetchError { throw fetchError }
        return rounds
    }
    func createMatchingRound(_ draft: ProjectMatchingRoundDraft) async throws -> String {
        throw TestError.unused
    }
    func updateMatchingRound(matchingRoundId: String,
                             update: ProjectMatchingRoundUpdate) async throws {}
    func deleteMatchingRound(matchingRoundId: String) async throws {}
    func autoDecide(matchingRoundId: String) async throws {}
}

private enum TestError: Error { case unused }
