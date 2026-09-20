//
//  MyProjectsView.swift
//  ProjectPresentation
//
//  Created by euijjang97 on 9/19/26.
//

import CoreDesignSystem
import CoreDI
import CoreUIComponents
import ProjectDomain
import SwiftUI
import UMCFoundation

/// 「내 프로젝트」 — 내가 관리하는 프로젝트(+초안)와 내 지원 내역.
///
/// 관리 영역은 일반 챌린저에게 빈 페이지로 오므로 비면 섹션째 숨긴다.
/// 행을 누르면 ``ProjectDestination/detail(projectId:)`` 로 간다.
struct MyProjectsView: View {

    // MARK: - Property

    @State private var viewModel: MyProjectsViewModel
    @State private var alertPrompt: AlertPrompt?
    @Environment(ErrorHandler.self) private var errorHandler

    fileprivate enum Constants {
        static let managedHeader = "내가 관리하는 프로젝트"
        static let applicationsHeader = "내 지원 내역"
        static let applicationsEmpty = "지원 내역이 없어요"
        static let allStatusTitle = "전체"
        static let statusFilterTitle = "지원 상태"
        static let statusFilterIcon = "line.3.horizontal.decrease.circle"
        static let gisuMenuTitle = "기수 선택"
        static let createDraft = "새 프로젝트 만들기"
    }

    // MARK: - Init

    init(container: DIContainer) {
        _viewModel = State(initialValue: MyProjectsViewModel(container: container))
    }

    // MARK: - Body

    var body: some View {
        List {
            managedSection
            applicationsSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .refreshable {
            await viewModel.fetch()
        }
        .navigation(naviTitle: NavigationTitle.Project.myProjects, displayMode: .inline)
        .umcDefaultBackground()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink(value: ProjectDestination.browse) {
                    Label("프로젝트 찾기", systemImage: "magnifyingglass")
                }
            }
            if !viewModel.generations.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    gisuMenu
                }
            }
        }
        .task {
            await viewModel.fetch()
        }
        .alertPrompt(item: $alertPrompt)
    }

    // MARK: - View Component

    @ViewBuilder
    private var managedSection: some View {
        switch viewModel.managed {
        case .idle, .loading:
            Section(Constants.managedHeader) {
                loadingRow
            }

        case .loaded(let managed):
            Section(Constants.managedHeader) {
                if !viewModel.reviewProjectIds.isEmpty {
                    NavigationLink(
                        value: ProjectDestination.applicationInbox(
                            projectIds: viewModel.reviewProjectIds,
                            decidableProjectIds: viewModel.decidableProjectIds
                        )
                    ) {
                        Label("전체 지원자 관리", systemImage: "tray.full")
                    }
                }
                if let draft = managed.draft {
                    projectRow(
                        projectId: draft.id,
                        name: draft.name,
                        subtitle: draft.description,
                        badge: ProjectStatus.draft.title
                    )
                }
                ForEach(managed.projects, id: \.id) { project in
                    projectRow(
                        projectId: project.id,
                        name: project.name,
                        subtitle: managed.memberCounts[project.id].map { "팀원 \($0)명" },
                        badge: project.status?.title
                    )
                    .onAppear {
                        if project.id == managed.projects.last?.id {
                            loadNextPage()
                        }
                    }
                }
                if viewModel.isLoadingNextPage {
                    loadingRow
                }
                if viewModel.canCreateDraft {
                    Button(action: confirmDraftCreation) {
                        Label(Constants.createDraft, systemImage: "plus.circle")
                    }
                    .disabled(viewModel.isCreatingDraft)
                } else if managed.isEmpty {
                    Text("관리하는 프로젝트가 없어요")
                        .appFont(.footnote, color: .grey500)
                }
            }

        case .failed(let error):
            Section(Constants.managedHeader) {
                InlineRetryRow(error: error) { await viewModel.fetchManaged() }
            }
        }
    }

    private var applicationsSection: some View {
        Section {
            switch viewModel.applications {
            case .idle, .loading:
                loadingRow

            case .loaded(let applications) where applications.isEmpty:
                Text(Constants.applicationsEmpty)
                    .appFont(.footnote, color: .grey500)

            case .loaded(let applications):
                ForEach(applications, id: \.listId) { application in
                    if let applicationId = application.applicationId {
                        NavigationLink(
                            value: applicationDestination(
                                projectId: application.projectId,
                                applicationId: applicationId
                            )
                        ) {
                            applicationRow(application)
                        }
                    } else {
                        NavigationLink(
                            value: ProjectDestination.detail(projectId: application.projectId)
                        ) {
                            applicationRow(application)
                        }
                    }
                }

            case .failed(let error):
                InlineRetryRow(error: error) { await viewModel.fetchApplications() }
            }
        } header: {
            HStack {
                Text(Constants.applicationsHeader)
                Spacer()
                statusFilterMenu
            }
        }
    }

    private var statusFilterMenu: some View {
        Menu {
            Picker(Constants.statusFilterTitle, selection: statusSelection) {
                Text(Constants.allStatusTitle)
                    .tag(ProjectApplicationStatus?.none)
                ForEach(ProjectApplicationStatus.myApplicationFilters, id: \.self) { status in
                    Text(status.title)
                        .tag(Optional(status))
                }
            }
        } label: {
            Label(
                viewModel.applicationStatus?.title ?? Constants.allStatusTitle,
                systemImage: Constants.statusFilterIcon
            )
            .appFont(.footnote)
        }
    }

    private var gisuMenu: some View {
        Menu {
            Picker(Constants.gisuMenuTitle, selection: gisuSelection) {
                ForEach(viewModel.generations) { generation in
                    Text("\(generation.gen)기")
                        .tag(Optional(generation.gisuId))
                }
            }
        } label: {
            Text(viewModel.selectedGeneration.map { "\($0)기" } ?? Constants.gisuMenuTitle)
        }
    }

    private func projectRow(
        projectId: String,
        name: String,
        subtitle: String?,
        badge: String?
    ) -> some View {
        NavigationLink(value: ProjectDestination.detail(projectId: projectId)) {
            HStack(spacing: DefaultSpacing.spacing12) {
                VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                    Text(name)
                        .appFont(.subheadline, weight: .semibold, color: .grey900)
                    if let subtitle {
                        Text(subtitle)
                            .appFont(.footnote, color: .grey500)
                    }
                }
                Spacer()
                if let badge {
                    InfoBadge(badge)
                }
            }
            .padding(.vertical, DefaultSpacing.spacing4)
        }
    }

    private func applicationRow(_ application: MyProjectApplication) -> some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                Text(application.project?.name ?? "-")
                    .appFont(.subheadline, weight: .semibold, color: .grey900)
                if let phase = application.matchingRound?.phase {
                    Text(phase.title)
                        .appFont(.footnote, color: .grey500)
                }
            }
            Spacer()
            if let status = application.status {
                InfoBadge(status.title)
            }
        }
        .padding(.vertical, DefaultSpacing.spacing4)
    }

    private var loadingRow: some View {
        Progress(size: .small)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Function

    private var statusSelection: Binding<ProjectApplicationStatus?> {
        Binding(
            get: { viewModel.applicationStatus },
            set: { status in
                Task { await viewModel.selectApplicationStatus(status) }
            }
        )
    }

    private var gisuSelection: Binding<String?> {
        Binding(
            get: { viewModel.selectedGisuId },
            set: { gisuId in
                guard let gisuId else { return }
                Task { await viewModel.selectGisu(gisuId) }
            }
        )
    }

    private func loadNextPage() {
        Task {
            do {
                try await viewModel.loadNextPage()
            } catch {
                errorHandler.handle(
                    error,
                    context: ErrorContext(feature: "Project", action: "loadManagedProjects")
                )
            }
        }
    }

    private func confirmDraftCreation() {
        alertPrompt = AlertPrompt(
            title: Constants.createDraft,
            message: "선택한 기수에 프로젝트 초안을 만들까요?",
            positiveBtnTitle: "만들기",
            positiveBtnAction: createDraft,
            negativeBtnTitle: "취소"
        )
    }

    private func createDraft() {
        Task {
            do {
                try await viewModel.createDraft()
            } catch {
                errorHandler.handle(
                    error,
                    context: ErrorContext(feature: "Project", action: "createDraftProject")
                )
            }
        }
    }

    private func applicationDestination(
        projectId: String,
        applicationId: String
    ) -> ProjectDestination {
        .editApplication(projectId: projectId, applicationId: applicationId)
    }
}
