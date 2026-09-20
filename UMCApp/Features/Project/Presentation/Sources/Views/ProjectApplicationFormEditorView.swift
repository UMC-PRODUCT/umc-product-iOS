//
//  ProjectApplicationFormEditorView.swift
//  ProjectPresentation
//
//  Created by euijjang97 on 9/20/26.
//

import CoreDI
import CoreDesignSystem
import CoreUIComponents
import ProjectDomain
import SwiftUI
import UMCFoundation

struct ProjectApplicationFormEditorView: View {

    // MARK: - Property

    @State private var viewModel: ProjectApplicationFormEditorViewModel
    @Environment(ErrorHandler.self) private var errorHandler

    // MARK: - Init

    init(container: DIContainer, projectId: String) {
        _viewModel = State(
            initialValue: ProjectApplicationFormEditorViewModel(
                container: container,
                projectId: projectId
            )
        )
    }

    // MARK: - Body

    var body: some View {
        content
            .navigationTitle("지원 폼 편집")
            .navigationBarTitleDisplayMode(.inline)
            .umcDefaultBackground()
            .toolbar {
                ToolBarCollection.ConfirmBtn(
                    action: save,
                    disable: !viewModel.canSave,
                    isLoading: viewModel.isSaving,
                    dismissOnTap: false
                )
            }
            .task { await viewModel.fetch() }
    }

    // MARK: - View Component

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            Progress()

        case .loaded:
            Form {
                Section("폼 정보") {
                    TextField("지원 폼 제목", text: $viewModel.title)
                    TextField("설명", text: $viewModel.formDescription, axis: .vertical)
                }
                ForEach($viewModel.sections) { $section in
                    sectionEditor(section: $section)
                }
                Section {
                    Button(action: viewModel.addSection) {
                        Label("섹션 추가", systemImage: "plus")
                    }
                }
            }
            .scrollContentBackground(.hidden)

        case .failed(let error):
            RetryContentUnavailableView(
                title: "지원 폼을 불러오지 못했어요",
                systemImage: "list.clipboard",
                description: error.userMessage,
                isRetrying: viewModel.loadState.isLoading,
                error: error,
                retryAction: { await viewModel.fetch() }
            )
        }
    }

    private func sectionEditor(
        section: Binding<ProjectFormSectionDraft>
    ) -> some View {
        Section {
            TextField("섹션 제목", text: section.title)
            TextField("섹션 설명", text: section.sectionDescription, axis: .vertical)
            Picker("노출 대상", selection: section.type) {
                ForEach(ProjectFormSectionType.allCases.filter { $0 != .unknown }, id: \.self) {
                    Text($0.title).tag($0)
                }
            }
            if section.wrappedValue.type == .part {
                DisclosureGroup("노출 파트") {
                    ForEach(UMCPartType.allCases, id: \.self) { part in
                        Toggle(part.name, isOn: partSelection(part, section: section))
                    }
                }
            }
            ForEach(section.questions) { $question in
                questionEditor(
                    question: $question,
                    sectionId: section.wrappedValue.id
                )
            }
            Button {
                viewModel.addQuestion(sectionId: section.wrappedValue.id)
            } label: {
                Label("질문 추가", systemImage: "plus.circle")
            }
        } header: {
            HStack {
                let title = section.wrappedValue.title
                Text(title.isEmpty ? "새 섹션" : title)
                Spacer()
                Button(role: .destructive) {
                    viewModel.sections.removeAll { $0.id == section.wrappedValue.id }
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }

    private func questionEditor(
        question: Binding<ProjectFormQuestionDraft>,
        sectionId: UUID
    ) -> some View {
        DisclosureGroup(
            question.wrappedValue.title.isEmpty ? "새 질문" : question.wrappedValue.title
        ) {
            TextField("질문 제목", text: question.title)
            TextField("질문 설명", text: question.questionDescription, axis: .vertical)
            Picker("유형", selection: question.type) {
                ForEach(ProjectQuestionType.allCases.filter { $0 != .unknown }, id: \.self) {
                    Text($0.title).tag($0)
                }
            }
            Toggle("필수 질문", isOn: question.isRequired)
            if question.wrappedValue.type.usesOptions {
                ForEach(question.options) { $option in
                    HStack {
                        TextField("선택지", text: $option.content)
                        Toggle("기타", isOn: $option.isOther)
                            .labelsHidden()
                        Button(role: .destructive) {
                            question.wrappedValue.options.removeAll { $0.id == option.id }
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
                Button {
                    viewModel.addOption(
                        sectionId: sectionId,
                        questionId: question.wrappedValue.id
                    )
                } label: {
                    Label("선택지 추가", systemImage: "plus")
                }
            }
            Button("질문 삭제", role: .destructive) {
                guard let sectionIndex = viewModel.sections.firstIndex(
                    where: { $0.id == sectionId }
                ) else { return }
                viewModel.sections[sectionIndex].questions.removeAll {
                    $0.id == question.wrappedValue.id
                }
            }
        }
    }

    // MARK: - Function

    private func partSelection(
        _ part: UMCPartType,
        section: Binding<ProjectFormSectionDraft>
    ) -> Binding<Bool> {
        Binding(
            get: { section.wrappedValue.allowedParts.contains(part) },
            set: { selected in
                if selected {
                    section.wrappedValue.allowedParts.insert(part)
                } else {
                    section.wrappedValue.allowedParts.remove(part)
                }
            }
        )
    }

    private func save() {
        Task {
            do {
                try await viewModel.save()
            } catch {
                errorHandler.handle(
                    error,
                    context: ErrorContext(feature: "Project", action: "saveApplicationForm")
                )
            }
        }
    }
}
