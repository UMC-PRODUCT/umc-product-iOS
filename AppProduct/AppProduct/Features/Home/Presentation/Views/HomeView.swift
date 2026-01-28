//
//  HomeView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/19/26.
//

import SwiftUI

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
    @State var viewModel = HomeViewModel()
    
    /// 캘린더에서 선택된 날짜 (기본값: 현재 날짜)
    @State var selectedDate: Date = .init()
    
    /// 캘린더의 현재 표시 중인 월 (기본값: 현재 월)
    @State var currentMonth: Date = .init()
    
    /// 네비게이션 라우터 (화면 이동 담당)
    private var router: NavigationRouter {
        di.resolve(NavigationRouter.self)
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
                ToolBarCollection.BellBtn(action: { router.push(to: .home(.alarmHistory)) })
                ToolBarCollection.Logo(image: .logoLight)
            }
        }
    }
    
    // MARK: - Season Info
    
    /// 상단 기수 관련 정보 (남은 기간, 현재 기수 등)를 표시하는 카드 뷰
    @ViewBuilder
    private var seasonCard: some View {
        switch viewModel.seasonData {
        case .idle:
            Color.clear.task {
                print("hello")
            }
        case .loading:
            LoadingView(.home(.seasonLoading))
        case .loaded(let seasonData):
            seasonLoaded(seasonData)
        case .failed:
            Color.clear
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
        case .idle:
            Color.clear.task {
                print("hello")
            }
        case .loading:
            LoadingView(.home(.penaltyLoading))
        case .loaded(let generation):
            generationLoaded(generation)
        case .failed:
            Color.clear
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
            ScheduleCard(selectedDate: $selectedDate,
                         currentMonth: $currentMonth,
                         scheduledDates: viewModel.scheduleDates
            )
            .equatable()
            
            scheduleList
        })
        
    }
    
    /// 선택된 날짜의 상세 일정 리스트 표시
    @ViewBuilder
    private var scheduleList: some View {
        let schedules = viewModel.getShedules(selectedDate)
        
        if schedules.isEmpty {
            emptySchedule
        } else {
            LazyVStack(spacing: DefaultSpacing.spacing8) {
                ForEach(Array(schedules.enumerated()), id: \.offset) { index, schedule in
                    ScheduleListCard(data: schedule)
                        .equatable()
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
        case .idle:
            Color.clear.task {
                print("hello")
            }
        case .loading:
            LoadingView(.home(.recentNoticeLoading))
        case .loaded(let recentNoticeData):
            recentView(recentNoticeData)
        case .failed:
            Color.clear
        }
    }
    
    /// 로드된 최근 공지 데이터를 표시하는 리스트 뷰
    /// - Parameter recentNoticeData: 표시할 공지 데이터 배열
    @ViewBuilder
    private func recentView(_ recentNoticeData: [RecentNoticeData]) -> some View {
        if recentNoticeData.isEmpty {
            ContentUnavailableView(
                "최근 공지가 없습니다.",
                systemImage: "tray",
                description: Text("새로운 공지사항이 등록되면 이곳에 표시됩니다.")
            )
            .glassEffect(.regular, in: .containerRelative)
        } else {
            LazyVStack(spacing: DefaultSpacing.spacing8) {
                ForEach(recentNoticeData.prefix(Constants.recentCardCount), id: \.id) { data in
                    RecentNoticeCard(data: data)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environment(DIContainer())
    .environment(ErrorHandler())
}
