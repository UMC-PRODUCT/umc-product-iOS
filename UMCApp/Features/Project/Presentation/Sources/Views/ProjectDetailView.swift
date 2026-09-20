//
//  ProjectDetailView.swift
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

/// 프로젝트 상세 — 소개·PO·파트별 모집 현황, 권한이 있으면 팀원 구성까지.
struct ProjectDetailView: View {

    // MARK: - Property

    @State private var viewModel: ProjectDetailViewModel
    @State private var alertPrompt: AlertPrompt?
    @Environment(\.dismiss) private var dismiss
    @Environment(ErrorHandler.self) private var errorHandler

    fileprivate enum Constants {
        static let icon = "briefcase"
        static let failedTitle = "프로젝트를 불러오지 못했어요"
        static let logoSize = CGSize(width: 56, height: 56)
        static let infoHeader = "정보"
        static let productOwnerTitle = "PO"
        static let coProductOwnerTitle = "Co-PO"
        static let externalLinkTitle = "외부 링크"
        static let partQuotaHeader = "파트별 모집"
        static let membersHeader = "팀원"
        static let membersEmpty = "아직 팀원이 없어요"
        static let managementHeader = "프로젝트 관리"
    }

    // MARK: - Init

    init(container: DIContainer, projectId: String) {
        _viewModel = State(
            initialValue: ProjectDetailViewModel(container: container, projectId: projectId)
        )
    }

    // MARK: - Body

    var body: some View {
        content
            .navigation(naviTitle: NavigationTitle.Project.detail, displayMode: .inline)
            .umcDefaultBackground()
            .task {
                await viewModel.fetch()
            }
            .alertPrompt(item: $alertPrompt)
            .onChange(of: viewModel.didDelete) { _, didDelete in
                if didDelete { dismiss() }
            }
    }

    // MARK: - View Component

    @ViewBuilder
    private var content: some View {
        switch viewModel.project {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded(let project):
            List {
                headerSection(project)
                infoSection(project)
                managementSection(project)
                if !project.partQuotas.isEmpty {
                    partQuotaSection(project.partQuotas)
                }
                if let members = viewModel.members {
                    membersSection(members)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .refreshable {
                await viewModel.fetch()
            }

        case .failed(let error):
            RetryContentUnavailableView(
                title: Constants.failedTitle,
                systemImage: Constants.icon,
                description: error.userMessage,
                isRetrying: viewModel.project.isLoading,
                error: error,
                retryAction: { await viewModel.fetch() }
            )
        }
    }

    @ViewBuilder
    private func managementSection(_ project: ProjectDetail) -> some View {
        if let permission = viewModel.permission {
            Section(Constants.managementHeader) {
                if permission.canEditInfo.allowed {
                    NavigationLink(value: ProjectDestination.editInfo(projectId: project.id)) {
                        Label("기본 정보 수정", systemImage: "square.and.pencil")
                    }
                }
                if permission.member.canCreate.allowed || permission.member.canDelete.allowed {
                    NavigationLink(
                        value: ProjectDestination.manageMembers(projectId: project.id)
                    ) {
                        Label("팀원·보조 PM 관리", systemImage: "person.3")
                    }
                }
                if permission.canTransferOwnership.allowed {
                    NavigationLink(
                        value: ProjectDestination.transferOwnership(projectId: project.id)
                    ) {
                        Label("PM 소유권 양도", systemImage: "arrow.left.arrow.right")
                    }
                }
                if permission.application.canCreate.allowed {
                    NavigationLink(
                        value: ProjectDestination.editApplication(
                            projectId: project.id,
                            applicationId: nil
                        )
                    ) {
                        Label("프로젝트 지원", systemImage: "doc.badge.plus")
                    }
                }
                if permission.application.canReadList.allowed {
                    NavigationLink(value: ProjectDestination.applicants(
                        projectId: project.id,
                        canDecide: permission.application.canDecide.allowed
                    )) {
                        Label("지원자 관리", systemImage: "person.2")
                    }
                }
                let canOpenApplicationForm = permission.applicationForm.canRead.allowed
                    || permission.applicationForm.canCreate.allowed
                    || permission.applicationForm.canEdit.allowed
                if canOpenApplicationForm
                    && ProjectManagementPolicy.canSaveApplicationForm(
                        canCreate: permission.applicationForm.canCreate.allowed,
                        canEdit: permission.applicationForm.canEdit.allowed,
                        status: project.status
                    ) {
                    NavigationLink(
                        value: ProjectDestination.applicationForm(projectId: project.id)
                    ) {
                        Label("지원 폼 편집", systemImage: "list.clipboard")
                    }
                }
                if permission.status.canRequestReview.allowed && project.status == .draft {
                    Button(action: confirmSubmission) {
                        Label("검토 요청", systemImage: "paperplane")
                    }
                    .disabled(viewModel.isPerformingAction)
                }
                if ProjectManagementPolicy.canDelete(
                    capabilityAllowed: permission.canDelete.allowed,
                    status: project.status
                ) {
                    Button("프로젝트 삭제", role: .destructive, action: confirmDeletion)
                        .disabled(viewModel.isPerformingAction)
                }
            }
        }
    }

    private func headerSection(_ project: ProjectDetail) -> some View {
        Section {
            HStack(spacing: DefaultSpacing.spacing12) {
                if let logoImageURL = project.logoImageURL {
                    RemoteImage(urlString: logoImageURL, size: Constants.logoSize)
                }
                VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                    Text(project.name)
                        .appFont(.title3, weight: .semibold, color: .grey900)
                    if let status = project.status {
                        InfoBadge(status.title)
                    }
                }
            }
            if let description = project.description, !description.isEmpty {
                Text(description)
                    .appFont(.subheadline, color: .grey700)
            }
        }
    }

    private func infoSection(_ project: ProjectDetail) -> some View {
        Section(Constants.infoHeader) {
            LabeledContent(
                Constants.productOwnerTitle,
                value: project.productOwner?.displayName ?? "-"
            )
            if !project.coProductOwners.isEmpty {
                LabeledContent(
                    Constants.coProductOwnerTitle,
                    value: project.coProductOwners.map(\.displayName).joined(separator: ", ")
                )
            }
            if let externalLink = project.externalLink, let url = URL(string: externalLink) {
                Link(Constants.externalLinkTitle, destination: url)
            }
        }
    }

    private func partQuotaSection(_ partQuotas: [ProjectPartQuota]) -> some View {
        Section(Constants.partQuotaHeader) {
            ForEach(partQuotas, id: \.part) { partQuota in
                LabeledContent(partQuota.part.name) {
                    HStack(spacing: DefaultSpacing.spacing8) {
                        Text("\(partQuota.currentCount)/\(partQuota.quota)명")
                        InfoBadge(partQuota.status.title)
                    }
                }
            }
        }
    }

    private func membersSection(_ members: Loadable<ProjectMembers>) -> some View {
        Section(Constants.membersHeader) {
            switch members {
            case .idle, .loading:
                Progress(size: .small)
                    .frame(maxWidth: .infinity)

            case .loaded(let members) where members.headCount == 0:
                Text(Constants.membersEmpty)
                    .appFont(.footnote, color: .grey500)

            case .loaded(let members):
                if let productOwner = members.productOwner {
                    memberRow(productOwner, role: Constants.productOwnerTitle)
                }
                ForEach(members.coProductOwners, id: \.memberId) { member in
                    memberRow(member, role: Constants.coProductOwnerTitle)
                }
                ForEach(members.partGroups, id: \.part) { partGroup in
                    ForEach(partGroup.members, id: \.memberId) { member in
                        memberRow(member, role: partGroup.part.name)
                    }
                }

            case .failed(let error):
                InlineRetryRow(error: error) { await viewModel.fetchMembers() }
            }
        }
    }

    private func memberRow(_ member: ProjectTeamMember, role: String) -> some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                Text(member.displayName)
                    .appFont(.subheadline, weight: .semibold, color: .grey900)
                let detail = [member.schoolName, member.matchedRound?.phase?.title]
                    .compactMap { $0 }
                    .joined(separator: " · ")
                if !detail.isEmpty {
                    Text(detail)
                        .appFont(.footnote, color: .grey500)
                }
            }
            Spacer()
            Text(role)
                .appFont(.footnote, color: .grey500)
        }
    }

    // MARK: - Function

    private func confirmSubmission() {
        alertPrompt = AlertPrompt(
            title: "검토 요청",
            message: "프로젝트를 제출하면 검토 대기 상태로 전환돼요.",
            positiveBtnTitle: "요청",
            positiveBtnAction: submitForReview,
            negativeBtnTitle: "취소"
        )
    }

    private func confirmDeletion() {
        alertPrompt = AlertPrompt(
            title: "프로젝트 삭제",
            message: "삭제한 프로젝트는 복구할 수 없어요. 계속할까요?",
            positiveBtnTitle: "삭제",
            positiveBtnAction: deleteProject,
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: true
        )
    }

    private func submitForReview() {
        perform(action: "submitProject") {
            try await viewModel.submitForReview()
        }
    }

    private func deleteProject() {
        perform(action: "deleteProject") {
            try await viewModel.deleteProject()
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
