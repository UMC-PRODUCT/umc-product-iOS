//
//  ProjectApplicationFormEditorViewModel.swift
//  ProjectPresentation
//
//  Created by euijjang97 on 9/20/26.
//

import CoreDI
import Foundation
import ProjectDomain
import UMCFoundation

struct ProjectFormOptionDraft: Identifiable {
    let id = UUID()
    let optionId: String?
    var content: String
    var isOther: Bool
}

struct ProjectFormQuestionDraft: Identifiable {
    let id = UUID()
    let questionId: String?
    var type: ProjectQuestionType
    var title: String
    var questionDescription: String
    var isRequired: Bool
    var options: [ProjectFormOptionDraft]
}

struct ProjectFormSectionDraft: Identifiable {
    let id = UUID()
    let sectionId: String?
    var type: ProjectFormSectionType
    var allowedParts: Set<UMCPartType>
    var title: String
    var sectionDescription: String
    var questions: [ProjectFormQuestionDraft]
}

@Observable
@MainActor
final class ProjectApplicationFormEditorViewModel {

    // MARK: - Property

    private(set) var loadState: Loadable<ProjectApplicationForm?> = .idle
    private(set) var isSaving = false
    private(set) var canSave = false
    var title = ""
    var formDescription = ""
    var sections: [ProjectFormSectionDraft] = []

    private let projectId: String
    private let useCase: ProjectApplicationUseCaseProtocol
    private let projectUseCase: ProjectUseCaseProtocol

    // MARK: - Init

    init(container: DIContainer, projectId: String) {
        self.projectId = projectId
        let provider = container.resolve(ProjectUseCaseProviding.self)
        useCase = provider.applicationUseCase
        projectUseCase = provider.projectUseCase
    }

    // MARK: - Function

    func fetch() async {
        guard loadState.value == nil else { return }
        loadState = .loading
        async let projectTask = try? projectUseCase.fetchProject(projectId: projectId)
        async let permissionTask = try? projectUseCase.fetchPermissions(projectIds: [projectId])
            .first { $0.projectId == projectId }
        do {
            let form = try await useCase.fetchApplicationForm(projectId: projectId)
            title = form?.title ?? ""
            formDescription = form?.description ?? ""
            sections = form?.sections.map(Self.sectionDraft) ?? []
            loadState = .loaded(form)
        } catch {
            loadState = .failed(AppError.from(error))
        }
        let project = await projectTask
        let permission = await permissionTask
        canSave = ProjectManagementPolicy.canSaveApplicationForm(
            canCreate: permission?.applicationForm.canCreate.allowed == true,
            canEdit: permission?.applicationForm.canEdit.allowed == true,
            status: project?.status
        )
    }

    func addSection() {
        sections.append(ProjectFormSectionDraft(
            sectionId: nil,
            type: .common,
            allowedParts: [],
            title: "",
            sectionDescription: "",
            questions: []
        ))
    }

    func addQuestion(sectionId: UUID) {
        guard let index = sections.firstIndex(where: { $0.id == sectionId }) else { return }
        sections[index].questions.append(ProjectFormQuestionDraft(
            questionId: nil,
            type: .shortText,
            title: "",
            questionDescription: "",
            isRequired: false,
            options: []
        ))
    }

    func addOption(sectionId: UUID, questionId: UUID) {
        guard let sectionIndex = sections.firstIndex(where: { $0.id == sectionId }),
              let questionIndex = sections[sectionIndex].questions.firstIndex(
                where: { $0.id == questionId }
              )
        else { return }
        sections[sectionIndex].questions[questionIndex].options.append(
            ProjectFormOptionDraft(optionId: nil, content: "", isOther: false)
        )
    }

    func save() async throws {
        guard canSave else {
            throw AppError.validation(.invalidValue(
                field: "지원 폼",
                reason: "현재 상태나 권한으로는 저장할 수 없어요"
            ))
        }
        let formSections = try makeSections()
        isSaving = true
        defer { isSaving = false }
        let saved = try await useCase.saveApplicationForm(
            projectId: projectId,
            title: title.isEmpty ? nil : title,
            description: formDescription.isEmpty ? nil : formDescription,
            sections: formSections
        )
        loadState = .loaded(saved)
        sections = saved.sections.map(Self.sectionDraft)
    }

    private func makeSections() throws -> [ProjectFormSection] {
        try sections.enumerated().map { sectionIndex, section in
            let sectionTitle = section.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !sectionTitle.isEmpty else {
                throw AppError.validation(.empty(field: "섹션 제목"))
            }
            if section.type == .part && section.allowedParts.isEmpty {
                throw AppError.validation(.empty(field: "파트별 섹션의 노출 파트"))
            }
            let questions = try section.questions.enumerated().map {
                questionIndex, question in
                let questionTitle = question.title.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                guard !questionTitle.isEmpty else {
                    throw AppError.validation(.empty(field: "질문 제목"))
                }
                let options = question.type.usesOptions ? question.options : []
                if question.type.usesOptions && options.isEmpty {
                    throw AppError.validation(.empty(field: "선택형 질문의 선택지"))
                }
                return ProjectFormQuestion(
                    questionId: question.questionId,
                    type: question.type,
                    title: questionTitle,
                    description: question.questionDescription.isEmpty
                        ? nil : question.questionDescription,
                    isRequired: question.isRequired,
                    orderNo: String(questionIndex),
                    options: try options.enumerated().map { optionIndex, option in
                        let content = option.content.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                        guard !content.isEmpty else {
                            throw AppError.validation(.empty(field: "선택지"))
                        }
                        return ProjectFormOption(
                            optionId: option.optionId,
                            content: content,
                            orderNo: String(optionIndex),
                            isOther: option.isOther
                        )
                    }
                )
            }
            return ProjectFormSection(
                sectionId: section.sectionId,
                type: section.type,
                allowedParts: section.type == .part ? section.allowedParts : [],
                title: sectionTitle,
                description: section.sectionDescription.isEmpty
                    ? nil : section.sectionDescription,
                orderNo: String(sectionIndex),
                questions: questions
            )
        }
    }

    private static func sectionDraft(_ section: ProjectFormSection) -> ProjectFormSectionDraft {
        ProjectFormSectionDraft(
            sectionId: section.sectionId,
            type: section.type == .unknown ? .common : section.type,
            allowedParts: section.allowedParts,
            title: section.title,
            sectionDescription: section.description ?? "",
            questions: section.questions.map { question in
                ProjectFormQuestionDraft(
                    questionId: question.questionId,
                    type: question.type == .unknown ? .shortText : question.type,
                    title: question.title,
                    questionDescription: question.description ?? "",
                    isRequired: question.isRequired,
                    options: question.options.map {
                        ProjectFormOptionDraft(
                            optionId: $0.optionId,
                            content: $0.content,
                            isOther: $0.isOther
                        )
                    }
                )
            }
        )
    }
}
