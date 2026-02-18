//
//  HomeView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/19/26.
//

import SwiftUI
import ClockKit

/// 홈 화면의 메인 뷰입니다.
///
/// 기수 정보, 일정, 패널티 현황 및 최근 공지사항을 종합적으로 보여줍니다.
struct HomeView: View {
    
    // MARK: - Properties
    
    /// 의존성 주입 컨테이너
    @Environment(\.di) var di
    /// 에러 핸들러 객체
    @Environment(ErrorHandler.self) var errorHandler

    /// 홈 화면의 비즈니스 로직을 담당하는 뷰 모델
    @State private var viewModel: HomeViewModel

    /// 캘린더에서 선택된 날짜 (기본값: 현재 날짜)
    @State var selectedDate: Date = .init()

    /// 캘린더의 현재 표시 중인 월 (기본값: 현재 월)
    @State var currentMonth: Date = .init()

    /// 섹션별 재시도 로딩 상태
    @State private var isRetryingProfileSection: Bool = false
    @State private var isRetryingRecentNoticeSection: Bool = false

    /// Path Store
    private var pathStore: PathStore {
        di.resolve(PathStore.self)
    }

    /// 화면 진입 시 초기 데이터 로딩 수행 여부
    private let shouldFetchOnTask: Bool
    
    // MARK: - Init
    init(
        container: DIContainer,
        viewModel: HomeViewModel? = nil,
        selectedDate: Date = .init(),
        currentMonth: Date = .init(),
        shouldFetchOnTask: Bool = true
    ) {
        _viewModel = State(
            initialValue: viewModel ?? HomeViewModel(container: container)
        )
        _selectedDate = State(initialValue: selectedDate)
        _currentMonth = State(initialValue: currentMonth)
        self.shouldFetchOnTask = shouldFetchOnTask
    }
    
    // MARK: - Constants
    
    /// UI 구성에 사용되는 상수 모음입니다.
    private enum Constants {
        /// 최근 공지 표시 개수 (최대 5개)
        static let recentCardCount: Int = 5
        
        /// 최근 공지 섹션 타이틀 텍스트
        static let recentUpdateText: String = "최근 공지"
        
        /// 스크롤 위치 식별자 ID
        static let scrollId: String = "scroll"

    }
    
    // MARK: - Body
    var body: some View {
        // NavigationStack의 path를 PathStore에 바인딩하여 홈 내 네비게이션 상태를 유지합니다.
        NavigationStack(path: Binding(
            get: { pathStore.homePath },
            set: { pathStore.homePath = $0 }
        )) {
            // 스크롤 위치 제어를 위해 ScrollViewReader를 사용합니다.
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(spacing: DefaultSpacing.spacing24) {
                        seasonCard
                        generations
                        calendar
                        recentUpdate
                    }
                    .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
                }
                .contentMargins(.bottom, DefaultConstant.defaultContentBottomMargins, for: .scrollContent)
                .toolbar {
                    ToolBarCollection.BellBtn(action: { pathStore.homePath.append(.home(.alarmHistory)) })
                    ToolBarCollection.Logo(image: .logoLight)
                }
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                NavigationRoutingView(destination: destination)
            }
            .umcDefaultBackground()
            // 화면 진입 시 홈 화면에 필요한 모든 데이터를 한 번에 로드합니다.
            .task {
                #if DEBUG
                if let debugState = HomeDebugState.fromLaunchArgument() {
                    debugState.apply(to: viewModel, selectedDate: selectedDate)
                    return
                }
                #endif
                guard shouldFetchOnTask else { return }
                await viewModel.fetchAll()
            }
        }
    }
    
    // MARK: - Season Info
    
    /// 상단 기수 관련 정보 (남은 기간, 현재 기수 등)를 표시하는 카드 뷰
    @ViewBuilder
    private var seasonCard: some View {
        switch viewModel.seasonData {
        case .loading where isRetryingProfileSection:
            SectionErrorCard(content: .seasonInfo, isLoading: true) {
                Task { await retryProfileSection() }
            }
        case .idle, .loading:
            LoadingView(.home(.seasonLoading))
        case .loaded(let seasonData):
            seasonLoaded(seasonData)
        case .failed:
            SectionErrorCard(content: .seasonInfo, isLoading: isRetryingProfileSection) {
                Task { await retryProfileSection() }
            }
        }
    }
    
    private func seasonLoaded(_ seasonData: [SeasonType]) -> some View {
        HStack {
            ForEach(Array(seasonData.enumerated()), id: \.offset) { index, season in
                SeasonCard(type: season)
                    .equatable()
            }
        }
    }
    
    // MARK: - Penalty Info
    
    /// 기수별 패널티 현황을 보여주는 뷰
    @ViewBuilder
    private var generations: some View {
        switch viewModel.generationData {
        case .loading where isRetryingProfileSection:
            SectionErrorCard(content: .penaltyInfo, isLoading: true) {
                Task { await retryProfileSection() }
            }
        case .idle, .loading:
            LoadingView(.home(.penaltyLoading))
        case .loaded(let generation):
            generationLoaded(generation)
        case .failed:
            SectionErrorCard(content: .penaltyInfo, isLoading: isRetryingProfileSection) {
                Task { await retryProfileSection() }
            }
        }
    }
    
    @ViewBuilder
    private func generationLoaded(_ generation: [GenerationData]) -> some View {
        PenaltyCard(generations: generation)
            .equatable()
    }
    
    // MARK: - Calendar
    
    /// 캘린더 및 일정 리스트를 포함하는 뷰
    private var calendar: some View {
        VStack(spacing: DefaultSpacing.spacing8, content: {
            // 캘린더 카드: 선택 날짜와 현재 월 상태를 전달합니다.
            ScheduleCard(selectedDate: $selectedDate,
                         currentMonth: $currentMonth,
                         scheduledDates: viewModel.scheduleDates
            )
            .equatable()

            scheduleList
        })
        // 월 변경 시 해당 월의 일정을 다시 불러옵니다.
        .onChange(of: currentMonth) { _, newMonth in
            let calendar = Calendar.current
            let year = calendar.component(.year, from: newMonth)
            let month = calendar.component(.month, from: newMonth)
            Task {
                await viewModel.fetchSchedules(year: year, month: month)
            }
        }
    }
    
    /// 선택된 날짜의 상세 일정 리스트 표시
    @ViewBuilder
    private var scheduleList: some View {
        let schedules = viewModel.getSchedules(selectedDate)
        
        if schedules.isEmpty {
            emptySchedule
        } else {
            LazyVStack(spacing: DefaultSpacing.spacing8) {
                ForEach(schedules, id: \.id) { schedule in
                    Button(action: {
                        // 일정 상세 화면으로 이동하며 선택 날짜를 함께 전달합니다.
                        pathStore.homePath.append(
                            .home(
                                .detailSchedule(
                                    scheduleId: schedule.scheduleId,
                                    selectedDate: selectedDate
                                )
                            )
                        )
                    }) {
                        ScheduleListCard(data: schedule)
                            .equatable()
                    }
                    .buttonStyle(ScheduleCardPressStyle())
                }
            }
        }
    }
    
    /// 일정이 없을 때 표시되는 빈 상태 뷰
    private var emptySchedule: some View {
        ContentUnavailableView("일정이 없습니다.",
                               systemImage: "calendar.badge.exclamationmark",
                               description: Text("선택한 날짜에 등록된 일정이 없습니다.")
        )
        .glassEffect(.regular, in: .containerRelative)
    }
    
    // MARK: - Recent Notices
    
    /// 최근 공지사항 섹션 전체 뷰
    private var recentUpdate: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing12, content: {
            recentHeader
            sectionContent
        })
    }
    
    /// 최근 공지 섹션 헤더
    private var recentHeader: some View {
        Text(Constants.recentUpdateText)
            .appFont(.title3Emphasis, color: .grey900)
    }
    
    /// 최근 공지 데이터 상태(로딩, 성공, 실패)에 따른 컨텐츠 뷰
    @ViewBuilder
    private var sectionContent: some View {
        switch viewModel.recentNoticeData {
        case .loading where isRetryingRecentNoticeSection:
            SectionErrorCard(content: .recentNotice, isLoading: true) {
                Task { await retryRecentNoticeSection() }
            }
        case .idle, .loading:
            LoadingView(.home(.recentNoticeLoading))
        case .loaded(let recentNoticeData):
            recentView(recentNoticeData)
        case .failed:
            SectionErrorCard(content: .recentNotice, isLoading: isRetryingRecentNoticeSection) {
                Task { await retryRecentNoticeSection() }
            }
        }
    }

    /// 프로필 섹션(기수 카드 + 패널티) 재시도
    @MainActor
    private func retryProfileSection() async {
        guard !isRetryingProfileSection else { return }
        isRetryingProfileSection = true
        defer { isRetryingProfileSection = false }
        await viewModel.fetchProfile()
    }

    /// 최근 공지 섹션 재시도 (역할 정보 없으면 프로필부터 재조회)
    @MainActor
    private func retryRecentNoticeSection() async {
        guard !isRetryingRecentNoticeSection else { return }
        isRetryingRecentNoticeSection = true
        defer { isRetryingRecentNoticeSection = false }
        if viewModel.roles.isEmpty {
            await viewModel.fetchProfile()
        }
        await viewModel.fetchRecentNotices()
    }
    
    /// 로드된 최근 공지 데이터를 표시하는 리스트 뷰
    /// - Parameter recentNoticeData: 표시할 공지 데이터 배열
    @ViewBuilder
    private func recentView(_ recentNoticeData: [RecentNoticeData]) -> some View {
        if recentNoticeData.isEmpty {
            LoadingView(.home(.recentNoticeLoading))
        } else {
            LazyVStack(spacing: DefaultSpacing.spacing8) {
                ForEach(recentNoticeData.prefix(Constants.recentCardCount), id: \.id) { data in
                    RecentNoticeCard(data: data)
                }
            }
        }
    }
}

/// 일정 카드 탭 시 눌림 효과를 제공하는 ButtonStyle
private struct ScheduleCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.8), value: configuration.isPressed)
    }
}
