//
//  ProjectApplicantsView.swift
//  ProjectPresentation
//
//  Created by euijjang97 on 9/20/26.
//

import CoreDesignSystem
import CoreDI
import CoreUIComponents
import ProjectDomain
import SwiftUI

struct ProjectApplicantsView: View {

    // MARK: - Property

    @State private var viewModel: ProjectApplicantsViewModel

    // MARK: - Init

    init(container: DIContainer, projectId: String, canDecide: Bool) {
        _viewModel = State(initialValue: ProjectApplicantsViewModel(
            container: container,
            projectId: projectId,
            canDecide: canDecide
        ))
    }

    // MARK: - Body

    var body: some View {
        content
            .navigationTitle("지원자 관리")
            .navigationBarTitleDisplayMode(.inline)
            .umcDefaultBackground()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { statusMenu }
            }
            .task { await viewModel.fetch() }
    }

    // MARK: - View Component

    @ViewBuilder
    private var content: some View {
        switch viewModel.applications {
        case .idle, .loading:
            Progress()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let applications) where applications.isEmpty:
            ContentUnavailableView("지원자가 없어요", systemImage: "person.2")
        case .loaded(let applications):
            List(applications, id: \.applicationId) { application in
                NavigationLink(value: ProjectDestination.reviewApplication(
                    projectId: viewModel.projectId,
                    applicationId: application.applicationId,
                    canDecide: viewModel.canDecide
                )) {
                    ProjectApplicantRow(application: application)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .refreshable { await viewModel.fetch() }
        case .failed(let error):
            RetryContentUnavailableView(
                title: "지원자를 불러오지 못했어요",
                systemImage: "person.2",
                description: error.userMessage,
                isRetrying: viewModel.applications.isLoading,
                error: error,
                retryAction: { await viewModel.fetch() }
            )
        }
    }

    private var statusMenu: some View {
        Menu {
            Picker("지원 상태", selection: statusSelection) {
                Text("전체").tag(ProjectApplicationStatus?.none)
                ForEach(ProjectApplicationStatus.myApplicationFilters, id: \.self) { status in
                    Text(status.title).tag(Optional(status))
                }
            }
        } label: {
            Label(
                viewModel.statusFilter?.title ?? "전체",
                systemImage: "line.3.horizontal.decrease.circle"
            )
        }
    }

    private var statusSelection: Binding<ProjectApplicationStatus?> {
        Binding(
            get: { viewModel.statusFilter },
            set: { status in Task { await viewModel.selectStatus(status) } }
        )
    }
}

struct ProjectApplicantRow: View {
    let application: ProjectApplicationSummary

    var body: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                Text(application.applicant.displayName)
                    .appFont(.callout, weight: .semibold, color: .grey900)
                let detail = [
                    application.applicant.schoolName,
                    application.applicant.part?.name,
                    application.matchingRound?.phase?.title,
                ].compactMap { $0 }.joined(separator: " · ")
                if !detail.isEmpty {
                    Text(detail)
                        .appFont(.footnote, color: .grey500)
                }
            }
            Spacer()
            InfoBadge(application.status.title)
        }
        .padding(.vertical, DefaultSpacing.spacing4)
    }
}
