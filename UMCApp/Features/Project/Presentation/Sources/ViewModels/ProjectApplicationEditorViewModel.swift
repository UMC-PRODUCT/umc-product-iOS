//
//  ProjectApplicationEditorViewModel.swift
//  ProjectPresentation
//
//  Created by euijjang97 on 9/20/26.
//

import CoreDI
import Foundation
import ProjectDomain
import UMCFoundation

struct ProjectApplicationAnswerDraft: Equatable {
    var text = ""
    var selectedOptionIds: Set<String> = []
    var fileIds: [String] = []
}

@Observable
@MainActor
final class ProjectApplicationEditorViewModel {

    // MARK: - Property

    private(set) var form: Loadable<ProjectApplicationForm> = .idle
    private(set) var matchingRounds: Loadable<[ProjectMatchingRound]> = .idle
    private(set) var applicationId: String?
    private(set) var status: ProjectApplicationStatus?
    private(set) var isPerformingAction = false
    var selectedMatchingRoundId: String?
    var answers: [String: ProjectApplicationAnswerDraft] = [:]

    let projectId: String
    private let applicationUseCase: ProjectApplicationUseCaseProtocol
    private let matchingRoundUseCase: ProjectMatchingRoundUseCaseProtocol
    private let chapterId: String?
    private let now: () -> Date
    private var appliedMatchingRoundId: String?
    private var submittedEditingRejected = false

    // MARK: - Init

    init(container: DIContainer, projectId: String, applicationId: String?) {
        let provider = container.resolve(ProjectUseCaseProviding.self)
        self.projectId = projectId
        self.applicationId = applicationId
        self.applicationUseCase = provider.applicationUseCase
        self.matchingRoundUseCase = provider.matchingRoundUseCase
        self.chapterId = UserDefaults.standard.string(forKey: AppStorageKey.chapterId)
        self.now = Date.init
    }

    init(
        projectId: String,
        applicationId: String?,
        applicationUseCase: ProjectApplicationUseCaseProtocol,
        matchingRoundUseCase: ProjectMatchingRoundUseCaseProtocol,
        chapterId: String?,
        now: @escaping () -> Date = Date.init
    ) {
        self.projectId = projectId
        self.applicationId = applicationId
        self.applicationUseCase = applicationUseCase
        self.matchingRoundUseCase = matchingRoundUseCase
        self.chapterId = chapterId
        self.now = now
    }

    // MARK: - Computed Property

    var canEdit: Bool {
        applicationId == nil || status == .draft || canEditSubmittedApplication
    }

    var canEditSubmittedApplication: Bool {
        guard status == .submitted, !submittedEditingRejected,
              let appliedMatchingRoundId,
              let round = matchingRounds.value?.first(where: { $0.id == appliedMatchingRoundId }),
              round.phase != .randomMatching,
              let startsAt = round.startsAt, let endsAt = round.endsAt else { return false }
        let currentTime = now()
        return startsAt <= currentTime && currentTime <= endsAt
    }

    var submittedEditingMessage: String? {
        guard status == .submitted else { return nil }
        if canEditSubmittedApplication {
            return "제출한 지원서는 해당 매칭 차수의 지원 기간에만 수정할 수 있어요."
        }
        if matchingRounds.value == nil {
            return "수정 가능 기간을 확인하지 못했어요. 다시 불러와 주세요."
        }
        return "해당 매칭 차수의 지원 기간이 아니어서 수정할 수 없어요."
    }

    var canCancel: Bool { status == .draft || status == .submitted }

    var canSave: Bool {
        canEdit
            && form.value != nil
            && unsupportedQuestions.isEmpty
            && (applicationId != nil || selectedMatchingRoundId != nil)
    }

    var unsupportedQuestions: [ProjectFormQuestion] {
        form.value?.sections
            .flatMap(\.questions)
            .filter { Self.isUnsupported($0.type) } ?? []
    }

    // MARK: - Function

    func fetch() async {
        form = .loading
        do {
            if let applicationId {
                try await fetchExistingApplication(applicationId: applicationId)
            } else {
                try await fetchNewApplicationForm()
            }
        } catch {
            form = .failed(AppError.from(error))
            if applicationId == nil {
                matchingRounds = .failed(AppError.from(error))
            }
        }
    }

    func updateText(questionId: String, text: String) {
        var draft = answers[questionId] ?? ProjectApplicationAnswerDraft()
        draft.text = text
        answers[questionId] = draft
    }

    func setOption(questionId: String, optionId: String, allowsMultiple: Bool) {
        var draft = answers[questionId] ?? ProjectApplicationAnswerDraft()
        if allowsMultiple {
            if draft.selectedOptionIds.contains(optionId) {
                draft.selectedOptionIds.remove(optionId)
            } else {
                draft.selectedOptionIds.insert(optionId)
            }
        } else {
            draft.selectedOptionIds = [optionId]
        }
        answers[questionId] = draft
    }

    func save() async throws {
        guard !isPerformingAction else { return }
        try await saveAnswers()
    }

    private func saveAnswers() async throws {
        if let unsupportedQuestion = unsupportedQuestions.first {
            throw Self.unsupportedQuestionError(unsupportedQuestion)
        }
        guard canSave else {
            throw AppError.validation(.invalidValue(
                field: "지원서",
                reason: submittedEditingMessage ?? "매칭 차수와 필수 답변을 확인해 주세요"
            ))
        }
        let inputs = try answerInputs()
        isPerformingAction = true
        defer { isPerformingAction = false }

        let resolvedApplicationId: String
        if let applicationId {
            resolvedApplicationId = applicationId
        } else {
            guard let selectedMatchingRoundId else {
                throw AppError.validation(.empty(field: "매칭 차수"))
            }
            let created = try await applicationUseCase.createApplication(
                projectId: projectId,
                matchingRoundId: selectedMatchingRoundId
            )
            applicationId = created.applicationId
            status = created.status
            resolvedApplicationId = created.applicationId
        }
        do {
            let updated = try await applicationUseCase.updateAnswers(
                projectId: projectId,
                applicationId: resolvedApplicationId,
                answers: inputs
            )
            status = updated.status
        } catch {
            if status == .submitted, Self.isClosedRoundError(error) {
                submittedEditingRejected = true
                throw AppError.validation(.invalidValue(
                    field: "지원서",
                    reason: "해당 매칭 차수의 지원 기간이 종료되어 수정할 수 없어요"
                ))
            }
            throw error
        }
    }

    func submit() async throws {
        guard !isPerformingAction else { return }
        guard applicationId == nil || status == .draft else {
            throw AppError.validation(.invalidValue(
                field: "지원서", reason: "이미 제출한 지원서는 수정 저장을 이용해 주세요"
            ))
        }
        try await saveAnswers()
        guard let applicationId, status == .draft else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }
        let submitted = try await applicationUseCase.submitApplication(
            projectId: projectId,
            applicationId: applicationId
        )
        status = submitted.status
        appliedMatchingRoundId = selectedMatchingRoundId
        await fetchEditingRounds()
    }

    func cancel(reason: String?) async throws {
        guard let applicationId, canCancel else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }
        let cancelled = try await applicationUseCase.cancelApplication(
            projectId: projectId,
            applicationId: applicationId,
            reason: reason?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        )
        status = cancelled.status
    }

    private func answerInputs() throws -> [ProjectAnswerInput] {
        guard let sections = form.value?.sections else { return [] }
        return try sections.flatMap(\.questions).compactMap { question in
            guard let questionId = question.questionId else { return nil }
            let draft = answers[questionId] ?? ProjectApplicationAnswerDraft()
            if Self.isUnsupported(question.type) {
                throw Self.unsupportedQuestionError(question)
            }
            if question.isRequired && Self.isEmptyAnswer(draft, for: question.type) {
                throw AppError.validation(.empty(field: question.title))
            }
            let textValue: String?
            let selectedOptionIds: [String]
            let fileIds: [String]
            switch question.type {
            case .shortText, .longText:
                textValue = draft.text.nilIfEmpty
                selectedOptionIds = []
                fileIds = []
            case .radio, .checkbox, .dropdown:
                textValue = nil
                selectedOptionIds = draft.selectedOptionIds.sorted()
                fileIds = []
            case .portfolio:
                textValue = draft.text.nilIfEmpty
                selectedOptionIds = []
                fileIds = draft.fileIds
            case .file, .schedule, .unknown:
                throw Self.unsupportedQuestionError(question)
            }
            return ProjectAnswerInput(
                questionId: questionId,
                textValue: textValue,
                selectedOptionIds: selectedOptionIds,
                fileIds: fileIds
            )
        }
    }

    private func fetchExistingApplication(applicationId: String) async throws {
        let detail = try await applicationUseCase.fetchApplication(
            projectId: projectId,
            applicationId: applicationId
        )
        guard let response = detail.formResponse else {
            throw AppError.validation(.invalidValue(
                field: "지원서",
                reason: "지원 당시 질문과 답변을 확인할 수 없어요"
            ))
        }
        let snapshot = ProjectApplicationForm(
            projectId: projectId,
            applicationFormId: response.formId,
            title: nil,
            description: nil,
            sections: response.sections
        )
        status = Self.applicationStatus(
            detailStatus: detail.status,
            formResponseStatus: response.status
        )
        selectedMatchingRoundId = detail.matchingRound?.id
        appliedMatchingRoundId = detail.matchingRound?.id
        submittedEditingRejected = false
        if status == .submitted { await fetchEditingRounds() }
        form = .loaded(snapshot)
        initializeAnswers(from: response.sections)
    }

    /// 전체 차수에서 지원서에 연결된 ID를 찾아 기간을 확인한다.
    /// 현재 열린 다른 차수를 근거로 과거 지원서의 편집을 허용하지 않는다.
    func fetchEditingRounds() async {
        matchingRounds = .loading
        do {
            matchingRounds = .loaded(try await matchingRoundUseCase.fetchMatchingRounds(
                chapterId: nil,
                time: nil
            ))
        } catch {
            matchingRounds = .failed(AppError.from(error))
        }
    }

    private static func isClosedRoundError(_ error: Error) -> Bool {
        switch AppError.from(error) {
        case .repository(.serverError(let code, _)):
            return code == "PROJECT-0208"
        case .network(.requestFailed(_, let data)):
            guard let data,
                  let body = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else { return false }
            return body["code"] as? String == "PROJECT-0208"
        default:
            return false
        }
    }

    private func fetchNewApplicationForm() async throws {
        matchingRounds = .loading
        let fetchedForm = try await applicationUseCase.fetchApplicationForm(
            projectId: projectId
        )
        guard let fetchedForm else {
            throw AppError.validation(.invalidValue(
                field: "지원 폼",
                reason: "아직 지원 폼이 공개되지 않았어요"
            ))
        }
        let rounds = try await matchingRoundUseCase.fetchMatchingRounds(
            chapterId: chapterId,
            time: Date()
        )
        form = .loaded(fetchedForm)
        matchingRounds = .loaded(rounds)
        selectedMatchingRoundId = rounds.first?.id
        initializeAnswers(from: fetchedForm.sections)
    }

    private static func applicationStatus(
        detailStatus: ProjectApplicationStatus?,
        formResponseStatus: ProjectFormResponseStatus
    ) -> ProjectApplicationStatus {
        if let detailStatus { return detailStatus }
        return switch formResponseStatus {
        case .draft: .draft
        case .submitted: .submitted
        case .unknown: .unknown
        }
    }

    private static func isUnsupported(_ type: ProjectQuestionType) -> Bool {
        type == .file || type == .schedule || type == .unknown
    }

    private static func isEmptyAnswer(
        _ draft: ProjectApplicationAnswerDraft,
        for type: ProjectQuestionType
    ) -> Bool {
        switch type {
        case .shortText, .longText:
            draft.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .radio, .checkbox, .dropdown:
            draft.selectedOptionIds.isEmpty
        case .portfolio:
            draft.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && draft.fileIds.isEmpty
        case .file, .schedule, .unknown:
            true
        }
    }

    private static func unsupportedQuestionError(
        _ question: ProjectFormQuestion
    ) -> AppError {
        AppError.validation(.invalidValue(
            field: question.title,
            reason: "이 질문 유형은 현재 앱에서 지원하지 않아요"
        ))
    }

    private func initializeAnswers(from sections: [ProjectFormSection]) {
        for question in sections.flatMap(\.questions) {
            guard let questionId = question.questionId else { continue }
            answers[questionId] = ProjectApplicationAnswerDraft(
                text: question.answer?.textValue ?? "",
                selectedOptionIds: Set(
                    question.answer?.selectedOptions.map(\.questionOptionId) ?? []
                ),
                fileIds: question.answer?.files.map(\.fileId) ?? []
            )
        }
    }
}

extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
