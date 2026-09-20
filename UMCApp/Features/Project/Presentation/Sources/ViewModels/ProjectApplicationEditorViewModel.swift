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

    // MARK: - Init

    init(container: DIContainer, projectId: String, applicationId: String?) {
        let provider = container.resolve(ProjectUseCaseProviding.self)
        self.projectId = projectId
        self.applicationId = applicationId
        self.applicationUseCase = provider.applicationUseCase
        self.matchingRoundUseCase = provider.matchingRoundUseCase
        self.chapterId = UserDefaults.standard.string(forKey: AppStorageKey.chapterId)
    }

    init(
        projectId: String,
        applicationId: String?,
        applicationUseCase: ProjectApplicationUseCaseProtocol,
        matchingRoundUseCase: ProjectMatchingRoundUseCaseProtocol,
        chapterId: String?
    ) {
        self.projectId = projectId
        self.applicationId = applicationId
        self.applicationUseCase = applicationUseCase
        self.matchingRoundUseCase = matchingRoundUseCase
        self.chapterId = chapterId
    }

    // MARK: - Computed Property

    var canEdit: Bool { applicationId == nil || status == .draft }

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
        if let unsupportedQuestion = unsupportedQuestions.first {
            throw Self.unsupportedQuestionError(unsupportedQuestion)
        }
        guard canSave else {
            throw AppError.validation(.invalidValue(
                field: "지원서",
                reason: "매칭 차수와 필수 답변을 확인해 주세요"
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
        let updated = try await applicationUseCase.updateAnswers(
            projectId: projectId,
            applicationId: resolvedApplicationId,
            answers: inputs
        )
        status = updated.status
    }

    func submit() async throws {
        try await save()
        guard let applicationId else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }
        let submitted = try await applicationUseCase.submitApplication(
            projectId: projectId,
            applicationId: applicationId
        )
        status = submitted.status
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
        form = .loaded(snapshot)
        initializeAnswers(from: response.sections)
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
        switch formResponseStatus {
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
