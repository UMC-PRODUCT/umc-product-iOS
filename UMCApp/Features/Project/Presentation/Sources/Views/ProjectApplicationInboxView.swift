//
//  ProjectApplicationInboxView.swift
//  ProjectPresentation
//
//  Created by euijjang97 on 9/20/26.
//

import CoreDI
import CoreUIComponents
import SwiftUI

struct ProjectApplicationInboxView: View {

    // MARK: - Property

    @State private var viewModel: ProjectApplicationInboxViewModel

    // MARK: - Init

    init(container: DIContainer, projectIds: [String], decidableProjectIds: [String]) {
        _viewModel = State(initialValue: ProjectApplicationInboxViewModel(
            container: container,
            projectIds: projectIds,
            decidableProjectIds: decidableProjectIds
        ))
    }

    // MARK: - Body

    var body: some View {
        content
            .navigationTitle("전체 지원자")
            .navigationBarTitleDisplayMode(.inline)
            .umcDefaultBackground()
            .task { await viewModel.fetch() }
    }

    // MARK: - View Component

    @ViewBuilder
    private var content: some View {
        switch viewModel.sections {
        case .idle, .loading:
            Progress()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let sections) where sections.isEmpty:
            ContentUnavailableView("지원자가 없어요", systemImage: "person.2")
        case .loaded(let sections):
            List {
                ForEach(sections, id: \.projectId) { section in
                    Section("프로젝트 #\(section.projectId)") {
                        ForEach(section.applications, id: \.applicationId) { application in
                            NavigationLink(value: ProjectDestination.reviewApplication(
                                projectId: section.projectId,
                                applicationId: application.applicationId,
                                canDecide: section.canDecide
                            )) {
                                ProjectApplicantRow(application: application)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .refreshable { await viewModel.fetch() }
        case .failed(let error):
            RetryContentUnavailableView(
                title: "지원자함을 불러오지 못했어요",
                systemImage: "tray.full",
                description: error.userMessage,
                isRetrying: viewModel.sections.isLoading,
                error: error,
                retryAction: { await viewModel.fetch() }
            )
        }
    }
}
