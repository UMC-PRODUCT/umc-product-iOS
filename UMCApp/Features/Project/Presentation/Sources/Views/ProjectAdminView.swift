//
//  ProjectAdminView.swift
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

struct ProjectAdminView: View {

    // MARK: - Property

    @State private var viewModel: ProjectAdminViewModel
    @State private var quotaEditor: ProjectQuotaEditorState?
    @State private var roundEditor: ProjectRoundEditorState?
    @State private var abortEditor: ProjectAbortEditorState?

    fileprivate enum Constants {
        static let title = "프로젝트 운영"
        static let projectHeader = "프로젝트 운영"
        static let matchingRoundHeader = "매칭 차수"
        static let applicationStatisticsHeader = "지원 현황"
        static let matchingStatisticsHeader = "공개 매칭 요약"
        static let noProjects = "운영할 프로젝트가 없어요"
        static let noMatchingRounds = "등록된 매칭 차수가 없어요"
        static let forbiddenTitle = "접근 권한이 없어요"
        static let forbiddenDescription =
            "운영진 계정으로만 프로젝트 운영 화면을 "
            + "열 수 있어요."
        static let failedTitle = "운영 정보를 불러오지 못했어요"
    }

    // MARK: - Init

    init(container: DIContainer) {
        _viewModel = State(initialValue: ProjectAdminViewModel(container: container))
    }

    // MARK: - Body

    var body: some View {
        content
            .navigationTitle(Constants.title)
            .navigationBarTitleDisplayMode(.inline)
            .umcDefaultBackground()
            .toolbar {
                if viewModel.canManageMatchingRounds {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("차수 추가", systemImage: "plus") {
                            roundEditor = ProjectRoundEditorState(round: nil)
                        }
                    }
                }
            }
            .task {
                await viewModel.fetch()
            }
            .refreshable {
                await viewModel.fetch()
            }
            .alertPrompt(item: $viewModel.alertPrompt)
            .alert(
                "작업을 완료하지 못했어요",
                isPresented: commandErrorPresented,
                presenting: viewModel.commandError
            ) { _ in
                Button("확인") { viewModel.clearCommandError() }
            } message: { error in
                Text(error.userMessage)
            }
            .sheet(item: $quotaEditor) { editor in
                ProjectQuotaEditorView(editor: editor) { projectId, values in
                    await viewModel.updatePartQuotas(projectId: projectId, values: values)
                    return viewModel.commandError == nil
                }
            }
            .sheet(item: $roundEditor) { editor in
                ProjectMatchingRoundEditorView(editor: editor) { matchingRoundId, form in
                    await viewModel.saveMatchingRound(
                        matchingRoundId: matchingRoundId,
                        form: form
                    )
                }
            }
            .sheet(item: $abortEditor) { editor in
                ProjectAbortEditorView(editor: editor) { projectId, reason in
                    viewModel.confirmAbort(projectId: projectId, reason: reason)
                }
            }
    }

    // MARK: - View Component

    @ViewBuilder
    private var content: some View {
        if !viewModel.canAccess {
            ContentUnavailableView(
                Constants.forbiddenTitle,
                systemImage: "lock.fill",
                description: Text(Constants.forbiddenDescription)
            )
        } else {
            switch viewModel.dashboard {
            case .idle, .loading:
                Progress()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .loaded(let dashboard):
                List {
                    projectSection(dashboard)
                    applicationStatisticsSection(dashboard.statistics)
                    if viewModel.canManageMatchingRounds {
                        matchingRoundSection
                        matchingStatisticsSection
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)

            case .failed(let error):
                RetryContentUnavailableView(
                    title: Constants.failedTitle,
                    systemImage: "briefcase.fill",
                    description: error.userMessage,
                    isRetrying: viewModel.dashboard.isLoading,
                    error: error,
                    retryAction: { await viewModel.fetch() }
                )
            }
        }
    }

    private func projectSection(_ dashboard: ProjectAdminDashboard) -> some View {
        Section {
            if dashboard.projects.isEmpty {
                Text(Constants.noProjects)
                    .appFont(.footnote, color: .grey500)
            } else {
                ForEach(dashboard.projects, id: \.id) { project in
                    projectRow(project)
                }
            }

            if !viewModel.completableProjectIds.isEmpty {
                Button("완료 가능한 프로젝트 일괄 완료", role: .destructive) {
                    viewModel.confirmCompleteProjects()
                }
                .disabled(viewModel.isSubmitting)
            }
        } header: {
            Text(Constants.projectHeader)
        }
    }

    private func projectRow(_ project: ProjectSummary) -> some View {
        let actions = viewModel.actions(for: project.id)
        return HStack(spacing: DefaultSpacing.spacing12) {
            NavigationLink(value: ProjectDestination.detail(projectId: project.id)) {
                VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                    Text(project.name)
                        .appFont(.subheadline, weight: .semibold, color: .grey900)
                    if let status = project.status {
                        Text(status.title)
                            .appFont(.footnote, color: .grey500)
                    }
                }
            }

            if !actions.isEmpty {
                Menu {
                    if actions.contains(.publish) {
                        Button("공개 전환", systemImage: "paperplane") {
                            Task { await viewModel.publish(projectId: project.id) }
                        }
                    }
                    if actions.contains(.editPartQuota) {
                        Button("파트별 정원", systemImage: "person.3") {
                            quotaEditor = ProjectQuotaEditorState(project: project)
                        }
                    }
                    if actions.contains(.abort) {
                        Button(
                            "프로젝트 중단",
                            systemImage: "stop.circle",
                            role: .destructive
                        ) {
                            abortEditor = ProjectAbortEditorState(project: project)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color.grey600)
                }
                .disabled(viewModel.isSubmitting)
            }
        }
    }

    @ViewBuilder
    private func applicationStatisticsSection(
        _ statistics: ProjectChapterStatistics?
    ) -> some View {
        if let statistics {
            Section(Constants.applicationStatisticsHeader) {
                if let summary = statistics.summary,
                   !summary.roundApplicationStatistics.isEmpty {
                    ForEach(
                        Array(summary.roundApplicationStatistics.enumerated()),
                        id: \.offset
                    ) { _, item in
                        LabeledContent(
                            item.matchingRound?.phase?.title ?? "차수 미분류",
                            value: "지원 \(item.appliedMemberCount)명 · "
                                + "가능 \(item.availableMemberCount)명"
                        )
                    }
                } else {
                    LabeledContent("조회 프로젝트", value: "\(statistics.projects.count)개")
                }
            }
        }
    }

    private var matchingRoundSection: some View {
        Section(Constants.matchingRoundHeader) {
            switch viewModel.matchingRounds {
            case .idle, .loading:
                Progress(size: .small)
                    .frame(maxWidth: .infinity)

            case .loaded(let rounds) where rounds.isEmpty:
                Text(Constants.noMatchingRounds)
                    .appFont(.footnote, color: .grey500)

            case .loaded(let rounds):
                ForEach(rounds, id: \.id) { round in
                    matchingRoundRow(round)
                }

            case .failed(let error):
                InlineRetryRow(error: error) { await viewModel.fetchMatchingRoundData() }
            }
        }
    }

    private func matchingRoundRow(_ round: ProjectMatchingRound) -> some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                Text(round.name)
                    .appFont(.subheadline, weight: .semibold, color: .grey900)
                Text("\(round.phase.title) · \(round.type.title)")
                    .appFont(.footnote, color: .grey500)
            }
            Spacer()
            Menu {
                Button("수정", systemImage: "pencil") {
                    roundEditor = ProjectRoundEditorState(round: round)
                }
                Button("자동 선발 실행", systemImage: "wand.and.stars") {
                    viewModel.confirmAutoDecide(round)
                }
                Button("삭제", systemImage: "trash", role: .destructive) {
                    viewModel.confirmDeleteMatchingRound(round)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(Color.grey600)
            }
            .disabled(viewModel.isSubmitting)
        }
    }

    @ViewBuilder
    private var matchingStatisticsSection: some View {
        switch viewModel.matchingStatistics {
        case .idle:
            EmptyView()

        case .loading:
            Section(Constants.matchingStatisticsHeader) {
                Progress(size: .small)
                    .frame(maxWidth: .infinity)
            }

        case .loaded(let statistics):
            Section(Constants.matchingStatisticsHeader) {
                ForEach(
                    Array(statistics.roundMatchingStatistics.enumerated()),
                    id: \.offset
                ) { _, item in
                    LabeledContent(
                        item.matchingRound?.phase?.title ?? "차수 미분류",
                        value: "매칭 \(item.matchedMemberCount)명 · "
                            + "가능 \(item.availableMemberCount)명"
                    )
                }
                if let unclassified = statistics.unclassifiedMatchingStatistics {
                    LabeledContent("랜덤 매칭", value: "\(unclassified.matchedMemberCount)명")
                }
            }

        case .failed(let error):
            Section(Constants.matchingStatisticsHeader) {
                InlineRetryRow(error: error) { await viewModel.fetchMatchingRoundData() }
            }
        }
    }

    private var commandErrorPresented: Binding<Bool> {
        Binding(
            get: { viewModel.commandError != nil },
            set: { if !$0 { viewModel.clearCommandError() } }
        )
    }
}

private struct ProjectQuotaEditorState: Identifiable {
    let projectId: String
    let projectName: String
    let quotas: [UMCPartType: String]

    var id: String { projectId }

    init(project: ProjectSummary) {
        projectId = project.id
        projectName = project.name
        quotas = Dictionary(uniqueKeysWithValues: project.partQuotas.map { ($0.part, $0.quota) })
    }
}

private struct ProjectRoundEditorState: Identifiable {
    let matchingRoundId: String?
    let form: ProjectMatchingRoundForm

    var id: String { matchingRoundId ?? "new" }

    init(round: ProjectMatchingRound?) {
        matchingRoundId = round?.id
        form = ProjectMatchingRoundForm(round: round)
    }
}

private struct ProjectAbortEditorState: Identifiable {
    let projectId: String
    let projectName: String

    var id: String { projectId }

    init(project: ProjectSummary) {
        projectId = project.id
        projectName = project.name
    }
}

private struct ProjectQuotaEditorView: View {
    let editor: ProjectQuotaEditorState
    let onSave: (String, [UMCPartType: String]) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var values: [UMCPartType: String]
    @State private var isSaving = false

    init(
        editor: ProjectQuotaEditorState,
        onSave: @escaping (String, [UMCPartType: String]) async -> Bool
    ) {
        self.editor = editor
        self.onSave = onSave
        _values = State(initialValue: editor.quotas)
    }

    var body: some View {
        NavigationStack {
            Form {
                ForEach(UMCPartType.allCases, id: \.self) { part in
                    TextField(part.name, text: quotaBinding(for: part))
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle(editor.projectName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        Task {
                            isSaving = true
                            if await onSave(editor.projectId, values) { dismiss() }
                            isSaving = false
                        }
                    }
                    .disabled(values.isEmpty || isSaving)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func quotaBinding(for part: UMCPartType) -> Binding<String> {
        Binding(
            get: { values[part] ?? "" },
            set: { value in
                if value.isEmpty {
                    values.removeValue(forKey: part)
                } else {
                    values[part] = value
                }
            }
        )
    }
}

private struct ProjectMatchingRoundEditorView: View {
    let editor: ProjectRoundEditorState
    let onSave: (String?, ProjectMatchingRoundForm) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var form: ProjectMatchingRoundForm
    @State private var isSaving = false

    init(
        editor: ProjectRoundEditorState,
        onSave: @escaping (String?, ProjectMatchingRoundForm) async -> Bool
    ) {
        self.editor = editor
        self.onSave = onSave
        _form = State(initialValue: editor.form)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("기본 정보") {
                    TextField("차수 이름", text: $form.name)
                    TextField("설명", text: $form.description, axis: .vertical)
                    Picker("매칭 유형", selection: $form.type) {
                        ForEach(ProjectMatchingType.editableCases, id: \.self) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    Picker("차수", selection: $form.phase) {
                        ForEach(ProjectMatchingPhase.editableCases, id: \.self) { phase in
                            Text(phase.title).tag(phase)
                        }
                    }
                }
                Section("일정") {
                    DatePicker("시작", selection: $form.startsAt)
                    DatePicker("종료", selection: $form.endsAt)
                    DatePicker("결정 마감", selection: $form.decisionDeadline)
                }
            }
            .navigationTitle(
                editor.matchingRoundId == nil ? "매칭 차수 생성" : "매칭 차수 수정"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        Task {
                            isSaving = true
                            if await onSave(editor.matchingRoundId, form) { dismiss() }
                            isSaving = false
                        }
                    }
                    .disabled(!form.isValid || isSaving)
                }
            }
        }
    }
}

private struct ProjectAbortEditorView: View {
    let editor: ProjectAbortEditorState
    let onConfirm: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("중단 사유", text: $reason, axis: .vertical)
            }
            .navigationTitle(editor.projectName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("중단", role: .destructive) {
                        dismiss()
                        onConfirm(editor.projectId, reason)
                    }
                    .disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
