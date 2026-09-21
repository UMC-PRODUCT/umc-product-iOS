//
//  WorkbookView.swift
//  ActivityPresentation
//
//  Created by euijjang97 on 9/21/26.
//

import ActivityDomain
import CoreDI
import CoreDesignSystem
import CoreDomain
import CoreUIComponents
import SwiftUI
import UMCFoundation

struct WorkbookRoute: View {
    @Environment(\.di) private var di
    @Environment(ErrorHandler.self) private var errorHandler
    @State private var viewModel: WorkbookViewModel?
    var workbookId: String? = nil
    var endsAt: Date? = nil
    var onChanged: @MainActor () async -> Void = {}

    var body: some View {
        Group {
            if let viewModel {
                WorkbookView(viewModel: viewModel, isList: workbookId == nil)
            } else {
                ProgressView()
            }
        }
        .task {
            guard viewModel == nil else { return }
            viewModel = WorkbookViewModel(
                useCase: di.resolve(WorkbookUseCaseProtocol.self),
                profileUseCase: di.resolve(FetchMemberProfileUseCaseProtocol.self),
                errorHandler: errorHandler, workbookId: workbookId, endsAt: endsAt,
                onChanged: onChanged
            )
        }
    }
}

private struct WorkbookEditor: Identifiable {
    enum Target {
        case submit(WorkbookMission, String)
        case editSubmission(WorkbookMission, WorkbookSubmission)
        case feedback(WorkbookSubmission)
        case editFeedback(WorkbookFeedback)
    }
    let id = UUID()
    let target: Target
    var content: String {
        switch target {
        case .editSubmission(_, let submission): return submission.submittedContent ?? ""
        case .editFeedback(let feedback): return feedback.content
        default: return ""
        }
    }
    var needsContent: Bool {
        switch target {
        case .submit(let mission, _), .editSubmission(let mission, _):
            return mission.missionType != "PLAIN"
        default: return true
        }
    }
}

private struct WorkbookView: View {
    @State private var viewModel: WorkbookViewModel
    let isList: Bool
    @State private var editor: WorkbookEditor?

    init(viewModel: WorkbookViewModel, isList: Bool) {
        _viewModel = State(initialValue: viewModel)
        self.isList = isList
    }

    var body: some View {
        Group {
            if isList { listContent } else { detailContent }
        }
        .navigationTitle(isList ? "내 워크북" : "워크북 상세")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .alertPrompt(item: $viewModel.alertPrompt)
        .sheet(item: $editor) { item in
            WorkbookEditorView(editor: item, viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var listContent: some View {
        switch viewModel.listState {
        case .idle, .loading: ProgressView()
        case .failed(let error): retry(error.userMessage)
        case .loaded(let items):
            if items.isEmpty {
                ContentUnavailableView("배포된 워크북이 없습니다", systemImage: "book.closed")
            } else {
                List(items) { item in
                    if let id = item.challengerWorkbookId, !id.isEmpty {
                        NavigationLink {
                            WorkbookRoute(workbookId: id, endsAt: item.endsAt) {
                                await viewModel.refreshAfterChange()
                            }
                        } label: {
                            Text(item.title).appFont(.callout)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                            Text(item.title).appFont(.callout)
                            Text("아직 개인 워크북을 배포받지 않았습니다.")
                                .appFont(.footnote, color: .grey500)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch viewModel.detailState {
        case .idle, .loading: ProgressView()
        case .failed(let error):
            retry(viewModel.message ?? error.userMessage)
        case .loaded(let detail):
            List {
                SwiftUI.Section(detail.original?.title ?? "제출물 · 피드백") {
                    if let content = detail.original?.content {
                        Text(content).textSelection(.enabled)
                    }
                    if let description = detail.original?.description { Text(description) }
                    if let value = detail.original?.url, let url = URL(string: value),
                        ["https", "http"].contains(url.scheme?.lowercased() ?? "")
                    {
                        Link("원본 워크북 열기", destination: url)
                    }
                    if let content = detail.challenger.content {
                        Text(content).textSelection(.enabled)
                    }
                    if !viewModel.owns(detail) && !viewModel.canReview {
                        Text("읽기 전용 · 피드백은 담당 멘토와 같은 학교·기수 회장단, 시스템 관리자만 작성할 수 있습니다.")
                            .appFont(.footnote, color: .grey500)
                    }
                    if detail.original == nil {
                        Text("원본 열람 권한이 없어 제출물과 피드백만 표시합니다.")
                            .appFont(.footnote, color: .grey500)
                    }
                    if let message = viewModel.message {
                        Text(message).appFont(.footnote, color: .grey600)
                    }
                }
                ForEach(detail.original?.missionList ?? [], id: \.originalWorkbookMissionId) {
                    mission in
                    missionSection(mission, detail: detail)
                }
                if detail.original == nil {
                    ForEach(detail.challenger.submissions, id: \.missionSubmissionId) {
                        submission in
                        SwiftUI.Section("제출물") {
                            submissionContent(submission, mission: nil, detail: detail)
                        }
                    }
                }
            }
            .disabled(viewModel.isMutating || viewModel.needsRefresh)
        }
    }

    private func missionSection(_ mission: WorkbookMission, detail: WorkbookDetail) -> some View {
        SwiftUI.Section(mission.title) {
            Text("\(mission.missionType) · \(mission.isNecessary ? "필수" : "선택")")
                .appFont(.footnote, color: .grey500)
            if let description = mission.description { Text(description) }
            if let submission = detail.challenger.submissions.first(where: {
                $0.originalWorkbookMissionId == mission.originalWorkbookMissionId
            }) {
                submissionContent(submission, mission: mission, detail: detail)
            } else {
                Text(
                    viewModel.withdrawnMissionIds.contains(mission.originalWorkbookMissionId)
                        ? "철회한 미션입니다. 재제출할 수 없습니다." : "미제출")
                if viewModel.owns(detail) {
                    if let end = viewModel.endsAt {
                        Text("제출 기한: \(end.formatted(date: .abbreviated, time: .shortened)) 전")
                            .appFont(.footnote, color: .grey500)
                    } else {
                        Text("제출 기한을 확인할 수 없습니다. 내 워크북 목록에서 다시 열어주세요.")
                    }
                    Button("미션 제출") {
                        editor = WorkbookEditor(
                            target: .submit(
                                mission, detail.challenger.challengerWorkbookId
                            ))
                    }
                    .disabled(!viewModel.canSubmit(mission, detail: detail))
                }
            }
        }
    }

    @ViewBuilder
    private func submissionContent(
        _ submission: WorkbookSubmission, mission: WorkbookMission?, detail: WorkbookDetail
    ) -> some View {
        Text(submission.status).appFont(.callout, weight: .semibold)
        if let content = submission.submittedContent {
            Text(content).textSelection(.enabled)
        }
        if viewModel.owns(detail) {
            Text("수정은 스터디 시작일 한국 시간 00:00 전까지, 일정이 없으면 주차 종료 전까지 가능합니다.")
                .appFont(.footnote, color: .grey500)
            if let mission {
                Button("제출 수정") {
                    editor = WorkbookEditor(target: .editSubmission(mission, submission))
                }
            }
            Button("제출 철회", role: .destructive) {
                viewModel.confirmWithdrawal(submission)
            }
        }
        ForEach(submission.feedbacks, id: \.missionFeedbackId) { feedback in
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
                Text("피드백 · \(feedback.feedbackResult)").appFont(
                    .callout, weight: .semibold)
                Text(feedback.content).textSelection(.enabled)
                if feedback.reviewerMemberId == viewModel.memberId {
                    Text("수정: 작성 후 14일 이내 · 삭제: 기수 종료 전")
                        .appFont(.footnote, color: .grey500)
                    Button("피드백 수정") {
                        editor = WorkbookEditor(target: .editFeedback(feedback))
                    }
                    Button("피드백 삭제", role: .destructive) {
                        viewModel.confirmFeedbackDeletion(feedback)
                    }
                }
            }
        }
        if viewModel.canReview {
            Button("피드백 작성") {
                editor = WorkbookEditor(target: .feedback(submission))
            }
        }
    }

    private func retry(_ message: String) -> some View {
        RetryContentUnavailableView(
            title: "워크북을 불러오지 못했어요", systemImage: "book.closed",
            description: message, isRetrying: false
        ) { await viewModel.load() }
    }
}

private struct WorkbookEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let editor: WorkbookEditor
    let viewModel: WorkbookViewModel
    @State private var content: String
    @State private var result = "PASS"
    @State private var validationMessage: String?

    init(editor: WorkbookEditor, viewModel: WorkbookViewModel) {
        self.editor = editor
        self.viewModel = viewModel
        _content = State(initialValue: editor.content)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("내용", text: $content, axis: .vertical)
                    .lineLimit(4...12)
                if case .feedback = editor.target {
                    Picker("결과", selection: $result) {
                        Text("통과").tag("PASS")
                        Text("실패").tag("FAIL")
                    }
                }
                if let message = validationMessage ?? viewModel.message {
                    Text(message).appFont(.footnote, color: .grey600)
                }
                Button("저장") { Task { await save() } }
                    .buttonStyle(.glassProminent)
                    .disabled(viewModel.isMutating || viewModel.needsRefresh)
            }
            .navigationTitle("미션 · 피드백")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }.disabled(viewModel.isMutating)
                }
            }
            .interactiveDismissDisabled(viewModel.isMutating)
        }
    }

    private func save() async {
        guard
            !editor.needsContent
                || !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            validationMessage = "LINK·MEMO 미션과 피드백은 내용을 입력해 주세요."
            return
        }
        let mutation: WorkbookMutation
        switch editor.target {
        case .submit(let mission, let workbookId):
            guard case .loaded(let detail) = viewModel.detailState,
                viewModel.canSubmit(mission, detail: detail)
            else {
                validationMessage = "제출 기한이 지났거나 제출할 수 없는 미션입니다."
                return
            }
            mutation = .submit(
                missionId: mission.originalWorkbookMissionId,
                workbookId: workbookId, content: content.isEmpty ? nil : content)
        case .editSubmission(_, let submission):
            mutation = .editSubmission(id: submission.missionSubmissionId, content: content)
        case .feedback(let submission):
            mutation = .feedback(
                submissionId: submission.missionSubmissionId,
                content: content, result: result)
        case .editFeedback(let feedback):
            mutation = .editFeedback(id: feedback.missionFeedbackId, content: content)
        }
        if await viewModel.mutate(mutation) { dismiss() }
    }
}
