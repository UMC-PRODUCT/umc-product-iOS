//
//  HomeView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/19/26.
//

import SwiftUI

struct HomeView: View {
    
    @Environment(\.di) var di
    @State var viewModel = HomeViewModel()
    @State var selectedDate: Date = .init()
    @State var currentMonth: Date = .init()
    
    private var router: NavigationRouter {
        di.resolve(NavigationRouter.self)
    }
    
    // MARK: - Constant
    private enum Constants {
        static let recentCardCount: Int = 5
        
        static let recentUpdateText: String = "최근 공지"
        static let scrollId: String = "scroll"
    }
    
    // MARK: - Body
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(spacing: DefaultSpacing.spacing24) {
                    Color.clear
                        .frame(height: .zero)
                        .id(Constants.scrollId)
                    
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
    
    // MARK: - GenerationInfo
    
    /// 상단 기수 관련 정보 카드
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
    
    // MARK: - PenaltygetShedules
    
    /// 기수 별 패널티 정보
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
    
    // MARK: - Caneldar
    
    /// 기수 행사 일정 데이터
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
    
    /// 달력 일정 스케줄 리스트
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
    
    private var emptySchedule: some View {
        ContentUnavailableView("일정이 없습니다.",
                               systemImage: "calendar.badge.exclamationmark",
                               description: Text("선택한 날짜에 등록된 일정이 없습니다.")
        )
        .glassEffect(.regular, in: .containerRelative)
    }
    
    // MARK: - Recent
    private var recentUpdate: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing12, content: {
            recentHeader
            sectionContent
        })
    }
    
    private var recentHeader: some View {
        Text(Constants.recentUpdateText)
            .appFont(.title3Emphasis, color: .grey900)
    }
    
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
}
