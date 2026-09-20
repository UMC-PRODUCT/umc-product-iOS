//
//  ProjectMemberManagementView.swift
//  ProjectPresentation
//
//  Created by euijjang97 on 9/20/26.
//

import ActivityPresentation
import CoreDesignSystem
import CoreDI
import CoreDomain
import CoreUIComponents
import ProjectDomain
import SwiftUI
import UMCFoundation

struct ProjectMemberManagementView: View {

    // MARK: - Property

    @State private var viewModel: ProjectMemberManagementViewModel
    @State private var showsMemberPicker = false
    @State private var showsStatusEditor = false
    @State private var alertPrompt: AlertPrompt?
    @Environment(ErrorHandler.self) private var errorHandler

    fileprivate enum Constants {
        static let title = "팀원 관리"
        static let addHeader = "팀원·보조 PM 추가"
        static let memberHeader = "현재 팀원"
        static let statusTitle = "상태 변경"
    }

    // MARK: - Init

    init(container: DIContainer, projectId: String) {
        _viewModel = State(
            initialValue: ProjectMemberManagementViewModel(
                container: container,
                projectId: projectId
            )
        )
    }

    // MARK: - Body

    var body: some View {
        content
            .navigationTitle(Constants.title)
            .navigationBarTitleDisplayMode(.inline)
            .umcDefaultBackground()
            .alertPrompt(item: $alertPrompt)
            .sheet(isPresented: $showsMemberPicker, onDismiss: addSelectedMembers) {
                SelectedChallengerView(challenger: $viewModel.selectedChallengers)
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showsStatusEditor) {
                statusEditor
                    .presentationDetents([.medium])
            }
            .task { await viewModel.fetch() }
    }

    // MARK: - View Component

    @ViewBuilder
    private var content: some View {
        switch viewModel.members {
        case .idle, .loading:
            Progress()

        case .loaded(let members):
            List {
                if viewModel.canAddMember {
                    Section(Constants.addHeader) {
                        Picker("파트", selection: $viewModel.selectedPart) {
                            ForEach(UMCPartType.allCases, id: \.self) { part in
                                Text(part.name).tag(part)
                            }
                        }
                        Button {
                            showsMemberPicker = true
                        } label: {
                            Label("챌린저 선택", systemImage: "person.badge.plus")
                        }
                    }
                }
                Section(Constants.memberHeader) {
                    if let owner = members.productOwner {
                        memberRow(owner, role: "PM", canManage: false)
                    }
                    ForEach(members.coProductOwners, id: \.memberId) { member in
                        memberRow(
                            member,
                            role: "보조 PM",
                            canManage: viewModel.canManageMember
                        )
                    }
                    ForEach(members.partGroups, id: \.part) { group in
                        ForEach(group.members, id: \.memberId) { member in
                            memberRow(
                                member,
                                role: group.part.name,
                                canManage: viewModel.canManageMember
                            )
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)

        case .failed(let error):
            RetryContentUnavailableView(
                title: "팀원을 불러오지 못했어요",
                systemImage: "person.3",
                description: error.userMessage,
                isRetrying: viewModel.members.isLoading,
                error: error,
                retryAction: { await viewModel.fetch() }
            )
        }
    }

    private func memberRow(
        _ member: ProjectTeamMember,
        role: String,
        canManage: Bool
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                Text(member.displayName)
                    .appFont(.subheadline, weight: .semibold, color: .grey900)
                Text(role)
                    .appFont(.footnote, color: .grey500)
            }
            Spacer()
            if canManage {
                Menu {
                    Button(Constants.statusTitle) {
                        viewModel.selectedMember = member
                        showsStatusEditor = true
                    }
                    Button("팀에서 제거", role: .destructive) {
                        confirmRemoval(member)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    private var statusEditor: some View {
        NavigationStack {
            Form {
                Picker("상태", selection: $viewModel.selectedStatus) {
                    ForEach(ProjectMemberStatus.allCases.filter { $0 != .unknown }, id: \.self) {
                        Text($0.title).tag($0)
                    }
                }
                TextField("변경 사유 (필수)", text: $viewModel.statusReason, axis: .vertical)
            }
            .navigationTitle(Constants.statusTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolBarCollection.ConfirmBtn(
                    action: changeStatus,
                    disable: !viewModel.canChangeStatus,
                    isLoading: viewModel.isSubmitting,
                    dismissOnTap: false
                )
            }
        }
    }

    // MARK: - Function

    private func addSelectedMembers() {
        Task {
            do {
                try await viewModel.addSelectedMembers()
            } catch {
                handle(error, action: "addProjectMember")
            }
        }
    }

    private func confirmRemoval(_ member: ProjectTeamMember) {
        alertPrompt = AlertPrompt(
            title: "팀원 제거",
            message: "\(member.displayName)님을 프로젝트에서 제거할까요?",
            positiveBtnTitle: "제거",
            positiveBtnAction: {
                Task {
                    do {
                        try await viewModel.remove(member)
                    } catch {
                        handle(error, action: "removeProjectMember")
                    }
                }
            },
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: true
        )
    }

    private func changeStatus() {
        Task {
            do {
                try await viewModel.changeStatus()
                showsStatusEditor = false
            } catch {
                handle(error, action: "changeProjectMemberStatus")
            }
        }
    }

    private func handle(_ error: Error, action: String) {
        errorHandler.handle(
            error,
            context: ErrorContext(feature: "Project", action: action)
        )
    }
}
