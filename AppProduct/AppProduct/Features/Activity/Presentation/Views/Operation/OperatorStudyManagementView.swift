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
    @State private var swipeState = SwipeStateManager()

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
        ScrollView {
            LazyVStack(spacing: DefaultSpacing.spacing12) {
                ForEach(members) { member in
                    SwipeableRow(id: member.id, actionWidth: 156) {
                        OperatorStudyMemberCard(member: member)
                            .equatable()
                    } actions: {
                        HStack(spacing: 12) {
                            SwipeActionButton(
                                icon: "star.fill",
                                title: "베스트",
                                color: .orange
                            ) {
                                swipeState.close()
                            }

                            SwipeActionButton(
                                icon: "checkmark.circle.fill",
                                title: "검토",
                                color: .indigo500
                            ) {
                                swipeState.close()
                            }
                        }
                    }
                }
            }
            .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
        }
        .contentMargins(.bottom, DefaultConstant.defaultContentBottomMargins, for: .scrollContent)
        .environment(swipeState)
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
    OperatorStudyManagementView(
        container: AttendancePreviewData.container,
        errorHandler: AttendancePreviewData.errorHandler
    )
}
#endif
