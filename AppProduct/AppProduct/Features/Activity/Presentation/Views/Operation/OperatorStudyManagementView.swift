//
//  OperatorStudyManagementView.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/23/26.
//

import SwiftUI

/// Admin 모드의 스터디 관리 섹션
///
/// 운영진이 스터디와 활동을 관리하는 화면입니다.
struct OperatorStudyManagementView: View {

    // MARK: - Property

    @State private var viewModel: OperatorStudyManagementViewModel

    private let container: DIContainer
    private let errorHandler: ErrorHandler

    private var pathStore: PathStore {
        container.resolve(PathStore.self)
    }

    @State private var selectedTab: ManagementTab = .submission

    // MARK: - Constants

    private enum Constants {
        static let loadingPlaceholderHeight: CGFloat = 80
    }

    private enum ManagementTab: Int, CaseIterable {
        case submission
        case groupManagement

        var title: String {
            switch self {
            case .submission: "제출 현황"
            case .groupManagement: "스터디 그룹 관리"
            }
        }
    }

    // MARK: - Initializer

    init(container: DIContainer, errorHandler: ErrorHandler) {
        self.container = container
        self.errorHandler = errorHandler

        let useCase = container
            .resolve(ActivityUseCaseProviding.self)
            .fetchStudyMembersUseCase
        _viewModel = State(initialValue: OperatorStudyManagementViewModel(
            container: container,
            errorHandler: errorHandler,
            useCase: useCase
        ))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Picker("관리", selection: $selectedTab) {
                ForEach(ManagementTab.allCases, id: \.self) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
            .padding(.vertical, DefaultSpacing.spacing8)

            switch selectedTab {
            case .submission:
                submissionContentView

            case .groupManagement:
                groupManagementPlaceholder
            }
        }
        .task {
            if viewModel.membersState.isIdle {
                await viewModel.fetchMembers()
            }
        }
        .toolbar {
            if selectedTab == .submission {
                ToolBarCollection.StudyWeekFilter(
                    weeks: viewModel.weeks,
                    selection: $viewModel.selectedWeek,
                    onChange: viewModel.selectWeek
                )
                ToolBarCollection.StudyGroupFilter(
                    studyGroups: viewModel.studyGroups,
                    selection: $viewModel.selectedStudyGroup,
                    onChange: viewModel.selectStudyGroup
                )
            }
        }
        .sheet(
            item: $viewModel.selectedMemberForReview,
            onDismiss: { viewModel.presentPendingAlert() }
        ) { member in
            OperatorStudyReviewSheet(
                member: member,
                onApprove: { feedback in
                    viewModel.confirmReviewApproval(
                        member: member,
                        feedback: feedback
                    )
                },
                onReject: { feedback in
                    viewModel.confirmReviewRejection(
                        member: member,
                        feedback: feedback
                    )
                }
            )
        }
        .sheet(
            item: $viewModel.selectedMemberForBest,
            onDismiss: { viewModel.presentPendingAlert() }
        ) { member in
            OperatorBestWorkbookSheet(
                member: member,
                onSelect: { recommendation in
                    viewModel.confirmBestWorkbookSelection(
                        member: member,
                        recommendation: recommendation
                    )
                }
            )
        }
        .sheet(
            isPresented: $viewModel.showAddMemberSheet,
            onDismiss: { viewModel.applySelectedChallengers() }
        ) {
            SelectedChallengerView(
                challenger: $viewModel.selectedChallengers
            )
        }
        .sheet(isPresented: $viewModel.showEditSheet) {
            OperatorStudyGroupEditSheet(
                detail: viewModel.studyGroupDetail,
                onSave: { name, part in
                    viewModel.applyGroupEdit(
                        name: name,
                        part: part
                    )
                }
            )
        }
        .alertPrompt(item: $viewModel.alertPrompt)
    }

    // MARK: - Submission Content View

    @ViewBuilder
    private var submissionContentView: some View {
        switch viewModel.membersState {
        case .idle, .loading:
            loadingView

        case .loaded(let members):
            if members.isEmpty {
                emptyView
            } else {
                memberListView(members: members)
            }

        case .failed(let error):
            errorView(error: error)
        }
    }

    // MARK: - Group Management View

    private var groupManagementPlaceholder: some View {
        ScrollView {
//            ContentUnavailableView {
//                Label("스터디 그룹 관리", systemImage: "person.2.badge.gearshape")
//            } description: {
//                Text("준비 중입니다")
//            }
//            .padding(.top, DefaultSpacing.spacing32)
//            .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
            StudyGroupCard(
                detail: viewModel.studyGroupDetail,
                onEdit: { viewModel.showEditSheet = true },
                onDelete: { print("Delete") },
                onAddMember: {
                    viewModel.showAddMemberSheet = true
                },
                onSchedule: {
                    pathStore.activityPath.append(
                        .activity(
                            .studyScheduleRegistration(
                                studyName: viewModel
                                    .studyGroupDetail.name
                            )
                        )
                    )
                }
            )
            .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeBtnPadding)
        }
        .contentMargins(.bottom, DefaultConstant.defaultContentBottomMargins, for: .scrollContent)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        ScrollView {
            VStack(spacing: DefaultSpacing.spacing12) {
                ForEach(0..<3, id: \.self) { _ in
                    loadingPlaceholder
                }
            }
            .padding(.top, DefaultSpacing.spacing16)
            .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
        }
        .contentMargins(.bottom, DefaultConstant.defaultContentBottomMargins, for: .scrollContent)
    }

    private var loadingPlaceholder: some View {
        ConcentricRectangle(
            corners: .concentric(minimum: DefaultConstant.concentricRadius),
            isUniform: true
        )
        .fill(Color.grey100)
        .frame(height: Constants.loadingPlaceholderHeight)
        .overlay {
            ProgressView()
                .tint(.grey400)
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        ScrollView {
            ContentUnavailableView {
                Label("스터디원 관리", systemImage: "person.3")
            } description: {
                Text("스터디원이 없습니다")
            }
            .padding(.top, DefaultSpacing.spacing32)
            .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
        }
    }

    // MARK: - Member List View

    private func memberListView(members: [StudyMemberItem]) -> some View {
        List {
            ForEach(members) { member in
                OperatorStudyMemberCard(member: member)
                    .equatable()
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(
                        top: DefaultSpacing.spacing4,
                        leading: DefaultConstant.defaultSafeHorizon,
                        bottom: DefaultSpacing.spacing4,
                        trailing: DefaultConstant.defaultSafeHorizon
                    ))
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            viewModel.selectedMemberForReview = member
                        } label: {
                            Label("검토", systemImage: "checkmark.circle.fill")
                        }
                        .tint(.indigo500)

                        Button {
                            viewModel.selectedMemberForBest = member
                        } label: {
                            Label("베스트", systemImage: "trophy")
                        }
                        .tint(.orange)
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.bottom, DefaultConstant.defaultContentBottomMargins, for: .scrollContent)
    }

    // MARK: - Error View

    private func errorView(error: AppError) -> some View {
        ScrollView {
            ContentUnavailableView {
                Label("로딩 실패", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.localizedDescription)
            } actions: {
                Button {
                    Task {
                        await viewModel.fetchMembers()
                    }
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                        .renderingMode(.template)
                        .foregroundStyle(.indigo600)
                }
                .buttonStyle(.glassProminent)
            }
            .padding(.top, DefaultSpacing.spacing32)
            .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationStack {
        OperatorStudyManagementView(
            container: AttendancePreviewData.container,
            errorHandler: AttendancePreviewData.errorHandler
        )
    }
}
#endif
