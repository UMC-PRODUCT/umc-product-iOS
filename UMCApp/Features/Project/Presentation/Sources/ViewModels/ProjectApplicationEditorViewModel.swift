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
    private(set) var status: ProjectApplicationStatus = .draft
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

    var canEdit: Bool { status == .draft }

    var canCancel: Bool { status == .draft || status == .submitted }

    var canSave: Bool {
        canEdit && form.value != nil && (applicationId != nil || selectedMatchingRoundId != nil)
    }

    // MARK: - Function

    func fetch() async {
        form = .loading
        if applicationId == nil {
            matchingRounds = .loading
        }
        do {
            let fetchedForm = try await applicationUseCase.fetchApplicationForm(
                projectId: projectId
            )
            guard let fetchedForm else {
                throw AppError.validation(.invalidValue(
                    field: "지원 폼",
                    reason: "아직 지원 폼이 공개되지 않았어요"
                ))
            }
            form = .loaded(fetchedForm)
            initializeAnswers(from: fetchedForm.sections)

            if let applicationId {
                let detail = try await applicationUseCase.fetchApplication(
                    projectId: projectId,
                    applicationId: applicationId
                )
                status = detail.status ?? .draft
                selectedMatchingRoundId = detail.matchingRound?.id
                if let sections = detail.formResponse?.sections {
                    initializeAnswers(from: sections)
                }
            } else {
                let rounds = try await matchingRoundUseCase.fetchMatchingRounds(
                    chapterId: chapterId,
                    time: Date()
                )
                matchingRounds = .loaded(rounds)
                selectedMatchingRoundId = rounds.first?.id
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
        guard let applicationId, status != .cancelled else { return }
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
            if question.isRequired
                && draft.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && draft.selectedOptionIds.isEmpty
                && draft.fileIds.isEmpty {
                throw AppError.validation(.empty(field: question.title))
            }
            return ProjectAnswerInput(
                questionId: questionId,
                textValue: draft.text.nilIfEmpty,
                selectedOptionIds: draft.selectedOptionIds.sorted(),
                fileIds: draft.fileIds
            )
        }
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
