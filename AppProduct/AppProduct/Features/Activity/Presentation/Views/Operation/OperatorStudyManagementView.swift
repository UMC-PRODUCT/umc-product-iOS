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

    // MARK: - Constants

    private enum Constants {
        static let loadingPlaceholderHeight: CGFloat = 80
    }

    // MARK: - Initializer

    init(container: DIContainer, errorHandler: ErrorHandler) {
        self.container = container
        self.errorHandler = errorHandler

        _viewModel = State(initialValue: OperatorStudyManagementViewModel(
            container: container,
            errorHandler: errorHandler
        ))
    }

    // MARK: - Body

    var body: some View {
        Group {
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
        .task {
            if viewModel.membersState.isIdle {
                await viewModel.fetchMembers()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Picker("주차", selection: $viewModel.selectedWeek) {
                        ForEach(viewModel.weeks, id: \.self) { week in
                            Text("\(week)주차")
                                .tag(week)
                        }
                    }
                } label: {
                    Text("\(viewModel.selectedWeek)주차")
                        .appFont(.calloutEmphasis)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("스터디 그룹", selection: $viewModel.selectedStudyGroup) {
                        ForEach(viewModel.studyGroups, id: \.self) { group in
                            Label(group.name, systemImage: group.iconName)
                                .tag(group)
                        }
                    }
                    .onChange(of: viewModel.selectedStudyGroup) { _, newValue in
                        viewModel.selectStudyGroup(newValue)
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                }
            }
        }
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
                            // 검토 액션
                        } label: {
                            Label("검토", systemImage: "checkmark.circle.fill")
                        }
                        .tint(.indigo500)

                        Button {
                            // 베스트 액션
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
