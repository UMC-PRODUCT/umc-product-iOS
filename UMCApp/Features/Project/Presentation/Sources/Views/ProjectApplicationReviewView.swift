//
//  ProjectApplicationReviewView.swift
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

struct ProjectApplicationReviewView: View {

    // MARK: - Property

    @State private var viewModel: ProjectApplicationReviewViewModel
    @State private var alertPrompt: AlertPrompt?
    @Environment(ErrorHandler.self) private var errorHandler

    // MARK: - Init

    init(container: DIContainer, projectId: String, applicationId: String, canDecide: Bool) {
        _viewModel = State(initialValue: ProjectApplicationReviewViewModel(
            container: container,
            projectId: projectId,
            applicationId: applicationId,
            canDecide: canDecide
        ))
    }

    // MARK: - Body

    var body: some View {
        content
            .navigationTitle("지원서 상세")
            .navigationBarTitleDisplayMode(.inline)
            .umcDefaultBackground()
            .task { await viewModel.fetch() }
            .alertPrompt(item: $alertPrompt)
    }

    // MARK: - View Component

    @ViewBuilder
    private var content: some View {
        switch viewModel.application {
        case .idle, .loading:
            Progress()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let application):
            List {
                applicantSection(application)
                if let response = application.formResponse {
                    ForEach(response.sections, id: \.orderNo) { section in
                        Section(section.title) {
                            ForEach(section.questions, id: \.orderNo) { question in
                                answerRow(question)
                            }
                        }
                    }
                }
                if viewModel.canDecide && application.status == .submitted {
                    decisionSection
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .refreshable { await viewModel.fetch() }
        case .failed(let error):
            RetryContentUnavailableView(
                title: "지원서를 불러오지 못했어요",
                systemImage: "doc.text.magnifyingglass",
                description: error.userMessage,
                isRetrying: viewModel.application.isLoading,
                error: error,
                retryAction: { await viewModel.fetch() }
            )
        }
    }

    private func applicantSection(_ application: ProjectApplicationDetail) -> some View {
        Section("지원자") {
            LabeledContent("이름", value: application.applicant.displayName)
            if let schoolName = application.applicant.schoolName {
                LabeledContent("학교", value: schoolName)
            }
            if let part = application.applicant.part {
                LabeledContent("파트", value: part.name)
            }
            if let phase = application.matchingRound?.phase {
                LabeledContent("매칭 차수", value: phase.title)
            }
            if let status = application.status {
                LabeledContent("상태") { InfoBadge(status.title) }
            }
        }
    }

    private func answerRow(_ question: ProjectFormQuestion) -> some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            Text(question.title)
                .appFont(.subheadline, weight: .semibold, color: .grey900)
            Text(answerText(question.answer))
                .appFont(.subheadline, color: .grey600)
        }
        .padding(.vertical, DefaultSpacing.spacing4)
    }

    private var decisionSection: some View {
        Section("심사") {
            Button("합격") { confirmDecision(.approved) }
                .disabled(viewModel.isDeciding)
            Button("불합격", role: .destructive) { confirmDecision(.rejected) }
                .disabled(viewModel.isDeciding)
        }
    }

    // MARK: - Function

    private func answerText(_ answer: ProjectApplicationAnswer?) -> String {
        guard let answer else { return "답변 없음" }
        let selected = answer.selectedOptions.compactMap(\.answeredAsContent)
        let files = answer.files.compactMap { $0.originalFileName ?? $0.url }
        let values = [answer.textValue].compactMap { $0 } + selected + files
        return values.isEmpty ? "답변 없음" : values.joined(separator: ", ")
    }

    private func confirmDecision(_ decision: ProjectApplicationDecision) {
        let approved = decision == .approved
        alertPrompt = AlertPrompt(
            title: approved ? "합격 결정" : "불합격 결정",
            message: approved
                ? "이 지원자를 합격 처리할까요?"
                : "이 지원자를 불합격 처리할까요?",
            positiveBtnTitle: approved ? "합격" : "불합격",
            positiveBtnAction: { decide(decision) },
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: !approved
        )
    }

    private func decide(_ decision: ProjectApplicationDecision) {
        Task {
            do {
                try await viewModel.decide(decision, reason: nil)
            } catch {
                errorHandler.handle(
                    error,
                    context: ErrorContext(feature: "Project", action: "decideApplication")
                )
            }
        }
    }
}
