//
//  OperatorAttendanceSectionView.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/23/26.
//

import SwiftUI

/// Admin 모드의 출석 관리 섹션
///
/// 운영진이 출석을 관리하고 승인하는 화면입니다.
/// 세션별 출석 현황을 확인하고, 승인 대기 중인 요청을 처리할 수 있습니다.
struct OperatorAttendanceSectionView: View {

    // MARK: - Property

    @State private var viewModel: OperatorAttendanceViewModel
    @State private var selectedPlace: PlaceSearchInfo = .init(
        name: "",
        address: "",
        coordinate: .init(latitude: 0, longitude: 0)
    )

    private let container: DIContainer
    private let errorHandler: ErrorHandler

    // MARK: - Init

    init(container: DIContainer, errorHandler: ErrorHandler) {
        self.container = container
        self.errorHandler = errorHandler

        let useCase = container.resolve(ActivityUseCaseProviding.self)
        _viewModel = State(initialValue: OperatorAttendanceViewModel(
            container: container,
            errorHandler: errorHandler,
            useCase: useCase.operatorAttendanceUseCase
        ))
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            content
                .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
        }
        .contentMargins(.bottom, DefaultConstant.defaultContentBottomMargins, for: .scrollContent)
        .task {
            // 상위 컨테이너에서 한 번만 호출 (View 교체로 인한 Task 취소 방지)
            if viewModel.sessionsState.isIdle {
                await viewModel.fetchSessions()
            }
        }
        .alertPrompt(item: $viewModel.alertPrompt)
        .sheet(isPresented: $viewModel.showLocationSheet) {
            locationChangeSheet
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.sessionsState {
        case .idle, .loading:
            loadingView

        case .loaded(let sessions):
            if sessions.isEmpty {
                emptyView
            } else {
                sessionListView(sessions: sessions)
            }

        case .failed(let error):
            errorView(error: error)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: DefaultSpacing.spacing16) {
            ForEach(0..<2, id: \.self) { _ in
                loadingPlaceholder
            }
        }
        .padding(.top, DefaultSpacing.spacing16)
    }

    private var loadingPlaceholder: some View {
        ConcentricRectangle(
            corners: .concentric(minimum: DefaultConstant.concentricRadius),
            isUniform: true
        )
        .fill(Color.grey200)
        .frame(height: 200)
        .overlay {
            ProgressView()
                .tint(.grey400)
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        ContentUnavailableView {
            Label("출석 관리", systemImage: "checkmark.circle.badge.questionmark")
        } description: {
            Text("관리할 세션이 없습니다")
        }
        .padding(.top, DefaultSpacing.spacing32)
    }

    // MARK: - Session List View

    private func sessionListView(
        sessions: [OperatorSessionAttendance]) -> some View {
        LazyVStack(spacing: DefaultSpacing.spacing16) {
            ForEach(sessions) { sessionAttendance in
                OperatorSessionCard(
                    sessionAttendance: sessionAttendance,
                    onLocationTap: {
                        viewModel.locationButtonTapped(session: sessionAttendance.session)
                    },
                    onReasonTap: { member in
                        viewModel.reasonButtonTapped(member: member)
                    },
                    onRejectTap: { member in
                        viewModel.rejectButtonTapped(member: member, sessionId: sessionAttendance.id)
                    },
                    onApproveTap: { member in
                        viewModel.approveButtonTapped(member: member, sessionId: sessionAttendance.id)
                    }
                )
                .equatable()
            }
        }
        .padding(.top, DefaultSpacing.spacing16)
    }

    // MARK: - Error View

    private func errorView(error: AppError) -> some View {
        ContentUnavailableView {
            Label("로딩 실패", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("다시 시도") {
                Task {
                    await viewModel.fetchSessions()
                }
            }
            .buttonStyle(.glassProminent)
        }
        .padding(.top, DefaultSpacing.spacing32)
    }

    // MARK: - Location Change Sheet

    private var locationChangeSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
                if let session = viewModel.selectedSession {
                    // 현재 세션 정보
                    VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
                        Text("세션 정보")
                            .appFont(.subheadline, color: .grey600)

                        Text(session.info.title)
                            .appFont(.calloutEmphasis)
                    }

                    Divider()

                    // 장소 선택
                    VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
                        Text("새 위치 선택")
                            .appFont(.subheadline, color: .grey600)

                        PlaceSelectView(place: $selectedPlace)
                            .padding(DefaultConstant.defaultListPadding)
                            .background(.white, in: .rect(cornerRadius: 16))
                    }

                    Spacer()
                }
            }
            .padding()
            .navigationTitle("위치 변경")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolBarCollection.CancelBtn {
                    viewModel.showLocationSheet = false
                    resetSelectedPlace()
                }
                
                ToolBarCollection.ConfirmBtn(action: {
                    // TODO: 실제 위치 변경 API 호출 - [25.02.05] 이재원
                    viewModel.showLocationSheet = false
                    resetSelectedPlace()
                }, disable: selectedPlace.name.isEmpty)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Helper

    private func resetSelectedPlace() {
        selectedPlace = PlaceSearchInfo(
            name: "",
            address: "",
            coordinate: .init(latitude: 0, longitude: 0)
        )
    }
}

// MARK: - Preview

#Preview {
    OperatorAttendanceSectionView(
        container: AttendancePreviewData.container,
        errorHandler: AttendancePreviewData.errorHandler
    )
}
