//
//  ScheduleDetailView.swift
//  AppProduct
//
//  Created by euijjang97 on 2/13/26.
//

import SwiftUI

/// 일정 상세 화면
struct ScheduleDetailView: View {

    // MARK: - Property

    @State var viewModel: ScheduleDetailViewModel
    @Environment(\.di) private var di
    @Environment(\.dismiss) private var dismiss
    @Environment(ErrorHandler.self) private var errorHandler

    private enum Constants {
        static let loadingMessage: String = "일정 정보를 가져오는 중입니다."
        static let editLoadingMessage: String = "일정 정보를 불러오는 중입니다."
        static let detailTitle: String = "상세 안내"
        static let mapButtonTitle: String = "지도 보기"
    }

    // MARK: - Init

    init(scheduleId: Int, selectedDate: Date) {
        self._viewModel = .init(initialValue: .init(
            scheduleId: scheduleId,
            selectedDate: selectedDate
        ))
    }

    // MARK: - Body

    var body: some View {
        stateContent
        .navigation(naviTitle: .detailSchedule, displayMode: .inline)
        .toolbar { toolbarContent }
        .alertPrompt(item: $viewModel.alertPromprt)
        .fullScreenCover(
            isPresented: $viewModel.isShowModify,
            onDismiss: {
                Task { @MainActor in
                    let provider = di.resolve(HomeUseCaseProviding.self)
                    await viewModel.fetchScheduleDetail(
                        fetchScheduleDetailUseCase: provider.fetchScheduleDetailUseCase
                    )
                }
            },
            content: editCoverContent
        )
        .task {
            let provider = di.resolve(HomeUseCaseProviding.self)
            let authorizationUseCase = di.resolve(AuthorizationUseCaseProtocol.self)
            async let detailTask: () = viewModel.fetchScheduleDetail(
                fetchScheduleDetailUseCase: provider.fetchScheduleDetailUseCase
            )
            async let permissionTask: () = viewModel.fetchSchedulePermission(
                authorizationUseCase: authorizationUseCase
            )
            _ = await (detailTask, permissionTask)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.data {
        case .idle, .loading:
            Progress(message: Constants.loadingMessage, size: .regular)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let data):
            content(data)
                .task {
                    await viewModel.fetchRoadAddress(
                        latitude: data.latitude,
                        longitude: data.longitude
                    )
                }
        case .failed:
            Color.clear
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if let loadedData {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if viewModel.canEditSchedule {
                    Button(action: {
                        Task { @MainActor in
                            await openModifySheetIfPossible(with: loadedData)
                        }
                    }) {
                        Image(systemName: "pencil")
                    }
                }

                if viewModel.canDeleteSchedule {
                    Button(role: .destructive, action: {
                        viewModel.deleteAlertAction {
                            dismiss()
                            Task { @MainActor in
                                await deleteSchedule(scheduleId: loadedData.scheduleId)
                            }
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func editCoverContent() -> some View {
        if case .loaded(let data) = viewModel.data {
            NavigationStack {
                ScheduleRegistrationView(
                    container: di,
                    errorHandler: errorHandler,
                    mode: .edit,
                    prefill: data,
                    prefillRoadAddress: viewModel.roadAddress
                )
            }
        } else {
            Progress(message: Constants.editLoadingMessage, size: .regular)
        }
    }

    // MARK: - Helper

    /// 역지오코딩이 완료된 후 수정 시트를 표시합니다.
    ///
    /// 도로명 주소가 아직 조회되지 않은 경우 먼저 조회 후 수정 화면을 엽니다.
    @MainActor
    private func openModifySheetIfPossible(with data: ScheduleDetailData) async {
        if viewModel.roadAddress == nil {
            await viewModel.fetchRoadAddress(
                latitude: data.latitude,
                longitude: data.longitude
            )
        }
        viewModel.isShowModify = true
    }

    /// Loadable 상태에서 로드된 데이터를 추출합니다.
    private var loadedData: ScheduleDetailData? {
        switch viewModel.data {
        case .loaded(let data):
            return data
        case .idle, .loading, .failed:
            return nil
        }
    }

    /// 일정과 출석부를 함께 삭제합니다.
    /// - Parameter scheduleId: 삭제할 일정 ID
    @MainActor
    private func deleteSchedule(scheduleId: Int) async {
        do {
            let provider = di.resolve(HomeUseCaseProviding.self)
            try await provider.deleteScheduleUseCase.execute(
                scheduleId: scheduleId
            )
        } catch {
            errorHandler.handle(error, context: ErrorContext(
                feature: "Home",
                action: "deleteScheduleWithAttendance",
                retryAction: { [weak di] in
                    guard let di else { return }
                    let provider = di.resolve(HomeUseCaseProviding.self)
                    try? await provider.deleteScheduleUseCase.execute(
                        scheduleId: scheduleId
                    )
                }
            ))
        }
    }

    private func content(_ data: ScheduleDetailData) -> some View {
        ScrollView(content: {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing24, content: {
                topContent(data)
                detailDescription(data)
            })
        })
        .contentMargins(.horizontal, DefaultConstant.defaultSafeHorizon, for: .scrollContent)
    }

    private func topContent(_ data: ScheduleDetailData) -> some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing12, content: {
            Text(data.name)
                .appFont(.title2Emphasis, color: .black)

            SchedulePlaceDateInfo(
                data: data,
                selectedDate: viewModel.selectedDate,
                roadAddress: viewModel.roadAddress,
                onMapLinkTapped: {
                    viewModel.mapLinkTapped(
                        latitude: data.latitude,
                        longitude: data.longitude
                    )
                }
            )
            .equatable()
        })
    }

    private func detailDescription(_ data: ScheduleDetailData) -> some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing12, content: {
            Text(Constants.detailTitle)
                .appFont(.title2Emphasis, color: .black)

            Text(data.description)
                .appFont(.callout, color: .grey600)
                .multilineTextAlignment(.leading)
        })
    }
}

/// 일정 상세의 날짜/시간 및 장소 정보 표시 컴포넌트
///
/// Container-Presenter 패턴으로 Equatable을 준수하여 불필요한 리렌더링을 방지합니다.
private struct SchedulePlaceDateInfo: View, Equatable {

    // MARK: - Property

    let data: ScheduleDetailData
    let selectedDate: Date
    let roadAddress: String?
    let onMapLinkTapped: () -> Void

    private enum Constants {
        static let mapButtonTitle: String = "지도 보기"
    }

    // MARK: - Equatable

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.data == rhs.data
        && lhs.selectedDate == rhs.selectedDate
        && lhs.roadAddress == rhs.roadAddress
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: .zero) {
            dateTimeSection
            Divider()
            locationSection
        }
        .background {
            ConcentricRectangle(corners: .concentric(minimum: DefaultConstant.concentricRadius), isUniform: true)
                .fill(Color.white)
                .glass()
        }
    }

    // MARK: - Section

    private var dateTimeSection: some View {
        infoSection(iconName: "calendar", tintColor: .orange) {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                Text(selectedDate.toYearMonthDayWithWeekday())
                    .appFont(.calloutEmphasis)
                    .foregroundStyle(.black)

                Text(data.startsAt.timeRange(to: data.endsAt))
                    .appFont(.subheadline)
                    .foregroundStyle(.grey600)
            }
        }
    }

    private var locationSection: some View {
        infoSection(iconName: "mappin.and.ellipse", tintColor: .blue) {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                Text(data.locationName)
                    .appFont(.calloutEmphasis)
                    .foregroundStyle(.black)

                if let roadAddress {
                    Text(roadAddress)
                        .appFont(.subheadline)
                        .foregroundStyle(.grey600)
                }

                Button(Constants.mapButtonTitle, action: onMapLinkTapped)
                    .appFont(.footnote)
                    .foregroundStyle(.blue)
            }
        }
    }

    // MARK: - Component

    private func infoSection<Content: View>(
        iconName: String,
        tintColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: DefaultSpacing.spacing16) {
            infoIcon(systemName: iconName, tintColor: tintColor)
            content()
            Spacer()
        }
        .padding(DefaultSpacing.spacing16)
    }

    private func infoIcon(systemName: String, tintColor: Color) -> some View {
        Image(systemName: systemName)
            .foregroundStyle(tintColor)
            .font(.system(size: 20))
            .padding()
            .background(tintColor.opacity(0.4), in: .circle)
            .glassEffect(.clear, in: .circle)
    }
}
