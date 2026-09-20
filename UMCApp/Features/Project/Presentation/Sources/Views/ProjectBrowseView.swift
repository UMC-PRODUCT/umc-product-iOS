//
//  ProjectBrowseView.swift
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

struct ProjectBrowseView: View {

    // MARK: - Property

    @State private var viewModel: ProjectBrowseViewModel
    @Environment(ErrorHandler.self) private var errorHandler

    // MARK: - Init

    init(container: DIContainer) {
        _viewModel = State(initialValue: ProjectBrowseViewModel(container: container))
    }

    // MARK: - Body

    var body: some View {
        content
            .navigationTitle("프로젝트 찾기")
            .navigationBarTitleDisplayMode(.inline)
            .umcDefaultBackground()
            .task { await viewModel.fetch() }
    }

    // MARK: - View Component

    @ViewBuilder
    private var content: some View {
        switch viewModel.projects {
        case .idle, .loading:
            Progress()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded(let projects) where projects.isEmpty:
            ContentUnavailableView(
                "진행 중인 프로젝트가 없어요",
                systemImage: "briefcase",
                description: Text(
                    "현재 기수에 공개된 프로젝트가 생기면 "
                        + "여기에서 볼 수 있어요."
                )
            )

        case .loaded(let projects):
            List(projects, id: \.id) { project in
                NavigationLink(value: ProjectDestination.detail(projectId: project.id)) {
                    projectRow(project)
                }
                .onAppear {
                    if project.id == projects.last?.id { loadNextPage() }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .refreshable { await viewModel.fetch() }

        case .failed(let error):
            RetryContentUnavailableView(
                title: "프로젝트를 불러오지 못했어요",
                systemImage: "briefcase",
                description: error.userMessage,
                isRetrying: viewModel.projects.isLoading,
                error: error,
                retryAction: { await viewModel.fetch() }
            )
        }
    }

    private func projectRow(_ project: ProjectSummary) -> some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            HStack {
                Text(project.name)
                    .appFont(.callout, weight: .semibold, color: .grey900)
                Spacer()
                if let status = project.partQuotaStatus {
                    InfoBadge(status.title)
                }
            }
            if let description = project.description, !description.isEmpty {
                Text(description)
                    .appFont(.subheadline, color: .grey600)
                    .lineLimit(2)
            }
            if let productOwner = project.productOwner {
                Text("PM · \(productOwner.displayName)")
                    .appFont(.footnote, color: .grey500)
            }
        }
        .padding(.vertical, DefaultSpacing.spacing4)
    }

    // MARK: - Function

    private func loadNextPage() {
        Task {
            do {
                try await viewModel.loadNextPage()
            } catch {
                errorHandler.handle(
                    error,
                    context: ErrorContext(feature: "Project", action: "loadProjectBrowsePage")
                )
            }
        }
    }
}
