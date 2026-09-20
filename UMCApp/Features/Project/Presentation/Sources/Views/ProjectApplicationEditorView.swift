//
//  ProjectApplicationEditorView.swift
//  ProjectPresentation
//
//  Created by euijjang97 on 9/20/26.
//

import CoreDesignSystem
import CoreDI
import CoreUIComponents
import ProjectDomain
import SwiftUI
import UMCFoundation

struct ProjectApplicationEditorView: View {

    @State private var viewModel: ProjectApplicationEditorViewModel
    @State private var alertPrompt: AlertPrompt?
    @Environment(ErrorHandler.self) private var errorHandler

    init(container: DIContainer, projectId: String, applicationId: String?) {
        _viewModel = State(initialValue: ProjectApplicationEditorViewModel(
            container: container,
            projectId: projectId,
            applicationId: applicationId
        ))
    }

    var body: some View {
        content
            .navigationTitle("프로젝트 지원")
            .navigationBarTitleDisplayMode(.inline)
            .umcDefaultBackground()
            .task { await viewModel.fetch() }
            .alertPrompt(item: $alertPrompt)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.form {
        case .idle, .loading:
            Progress()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded(let form):
            Form {
                if let title = form.title, !title.isEmpty {
                    Section {
                        Text(title)
                            .appFont(.headline, color: .grey900)
                        if let description = form.description, !description.isEmpty {
                            Text(description)
                                .appFont(.subheadline, color: .grey600)
                        }
                    }
                }
                if viewModel.applicationId == nil {
                    matchingRoundSection
                }
                ForEach(form.sections, id: \.orderNo) { section in
                    Section(section.title) {
                        if let description = section.description, !description.isEmpty {
                            Text(description)
                                .appFont(.footnote, color: .grey500)
                        }
                        ForEach(section.questions, id: \.orderNo) { question in
                            questionField(question)
                        }
                    }
                }
                actionSection
            }
            .scrollContentBackground(.hidden)

        case .failed(let error):
            RetryContentUnavailableView(
                title: "지원서를 불러오지 못했어요",
                systemImage: "doc.text",
                description: error.userMessage,
                isRetrying: viewModel.form.isLoading,
                error: error,
                retryAction: { await viewModel.fetch() }
            )
        }
    }

    private var matchingRoundSection: some View {
        Section("지원 차수") {
            switch viewModel.matchingRounds {
            case .idle, .loading:
                Progress(size: .small)
            case .loaded(let rounds) where rounds.isEmpty:
                Text("현재 지원 가능한 매칭 차수가 없어요")
                    .appFont(.footnote, color: .grey500)
            case .loaded(let rounds):
                Picker("매칭 차수", selection: $viewModel.selectedMatchingRoundId) {
                    ForEach(rounds, id: \.id) { round in
                        Text(round.name).tag(Optional(round.id))
                    }
                }
            case .failed(let error):
                Text(error.userMessage)
                    .appFont(.footnote, color: .red500)
            }
        }
    }

    @ViewBuilder
    private func questionField(_ question: ProjectFormQuestion) -> some View {
        if let questionId = question.questionId {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
                Text(question.isRequired ? "\(question.title) *" : question.title)
                    .appFont(.subheadline, weight: .semibold, color: .grey900)
                if let description = question.description, !description.isEmpty {
                    Text(description)
                        .appFont(.footnote, color: .grey500)
                }
                switch question.type {
                case .radio, .checkbox, .dropdown:
                    ForEach(question.options, id: \.orderNo) { option in
                        if let optionId = option.optionId {
                            Toggle(
                                option.content,
                                isOn: optionBinding(
                                    questionId: questionId,
                                    optionId: optionId,
                                    allowsMultiple: question.type == .checkbox
                                )
                            )
                            .toggleStyle(.button)
                        }
                    }
                case .shortText, .longText, .portfolio:
                    TextField(
                        answerPlaceholder(for: question.type),
                        text: textBinding(questionId: questionId),
                        axis: question.type == .longText ? .vertical : .horizontal
                    )
                    .disabled(!viewModel.canEdit)
                case .file, .schedule, .unknown:
                    Label(
                        "이 질문 유형은 현재 앱에서 작성할 수 없어요.",
                        systemImage: "exclamationmark.triangle"
                    )
                    .appFont(.footnote, color: .red500)
                }
            }
            .padding(.vertical, DefaultSpacing.spacing4)
            .disabled(!viewModel.canEdit)
        }
    }

    private var actionSection: some View {
        Section {
            if viewModel.canEdit {
                Button("임시 저장", action: save)
                    .disabled(!viewModel.canSave || viewModel.isPerformingAction)
                Button("지원서 제출", action: confirmSubmission)
                    .disabled(!viewModel.canSave || viewModel.isPerformingAction)
            }
            if viewModel.applicationId != nil && viewModel.canCancel {
                Button("지원 철회", role: .destructive, action: confirmCancellation)
                    .disabled(viewModel.isPerformingAction)
            }
        } footer: {
            if let unsupportedQuestion = viewModel.unsupportedQuestions.first {
                Text(
                    "‘\(unsupportedQuestion.title)’ 질문은 아직 지원하지 않아 "
                        + "임시 저장과 제출을 할 수 없어요."
                )
            } else {
                Text("현재 상태: \(viewModel.status?.title ?? "작성 중")")
            }
        }
    }

    private func textBinding(questionId: String) -> Binding<String> {
        Binding(
            get: { viewModel.answers[questionId]?.text ?? "" },
            set: { viewModel.updateText(questionId: questionId, text: $0) }
        )
    }

    private func optionBinding(
        questionId: String,
        optionId: String,
        allowsMultiple: Bool
    ) -> Binding<Bool> {
        Binding(
            get: { viewModel.answers[questionId]?.selectedOptionIds.contains(optionId) == true },
            set: { isSelected in
                guard isSelected || allowsMultiple else { return }
                viewModel.setOption(
                    questionId: questionId,
                    optionId: optionId,
                    allowsMultiple: allowsMultiple
                )
            }
        )
    }

    private func answerPlaceholder(for type: ProjectQuestionType) -> String {
        switch type {
        case .portfolio: "포트폴리오 링크를 입력해 주세요"
        default: "답변을 입력해 주세요"
        }
    }

    private func save() {
        perform(action: "saveProjectApplication") { try await viewModel.save() }
    }

    private func confirmSubmission() {
        alertPrompt = AlertPrompt(
            title: "지원서 제출",
            message: "제출한 지원서는 더 이상 수정할 수 없어요. 제출할까요?",
            positiveBtnTitle: "제출",
            positiveBtnAction: submit,
            negativeBtnTitle: "취소"
        )
    }

    private func submit() {
        perform(action: "submitProjectApplication") { try await viewModel.submit() }
    }

    private func confirmCancellation() {
        alertPrompt = AlertPrompt(
            title: "지원 철회",
            message: "철회한 지원서는 되돌릴 수 없어요. 계속할까요?",
            positiveBtnTitle: "철회",
            positiveBtnAction: cancel,
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: true
        )
    }

    private func cancel() {
        perform(action: "cancelProjectApplication") {
            try await viewModel.cancel(reason: nil)
        }
    }

    private func perform(
        action: String,
        operation: @escaping @MainActor () async throws -> Void
    ) {
        Task {
            do {
                try await operation()
            } catch {
                errorHandler.handle(
                    error,
                    context: ErrorContext(feature: "Project", action: action)
                )
            }
        }
    }
}
