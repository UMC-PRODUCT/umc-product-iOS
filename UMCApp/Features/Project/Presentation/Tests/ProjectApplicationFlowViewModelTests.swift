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

    @Test("지원 철회 결과가 취소 상태로 전환된다")
    func cancellationUpdatesStatus() async throws {
        let applicationUseCase = ProjectApplicationUseCaseSpy()
        applicationUseCase.cancelledResult = .init(applicationId: "301", status: .cancelled)
        let viewModel = ProjectApplicationEditorViewModel(
            projectId: "101",
            applicationId: "301",
            applicationUseCase: applicationUseCase,
            matchingRoundUseCase: ProjectMatchingRoundUseCaseSpy(),
            chapterId: nil
        )

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
        formResponse: nil
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
    var submittedApplications: [SubmitCall] = []
    var cancelledApplications: [CancelCall] = []
    var singleApplicationQueries: [SingleQuery] = []
    var batchApplicationQueries: [BatchQuery] = []
    var decisions: [ProjectApplicationDecision] = []

    func fetchApplicationForm(projectId: String) async throws -> ProjectApplicationForm? { form }
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
        guard let detail else { throw TestError.unused }
        return detail
    }
}

private final class ProjectMatchingRoundUseCaseSpy:
    ProjectMatchingRoundUseCaseProtocol,
    @unchecked Sendable {

    var rounds: [ProjectMatchingRound] = []

    func fetchMatchingRounds(chapterId: String?, time: Date?) async throws
        -> [ProjectMatchingRound] { rounds }
    func createMatchingRound(_ draft: ProjectMatchingRoundDraft) async throws -> String {
        throw TestError.unused
    }
    func updateMatchingRound(matchingRoundId: String,
                             update: ProjectMatchingRoundUpdate) async throws {}
    func deleteMatchingRound(matchingRoundId: String) async throws {}
    func autoDecide(matchingRoundId: String) async throws {}
}

private enum TestError: Error { case unused }
