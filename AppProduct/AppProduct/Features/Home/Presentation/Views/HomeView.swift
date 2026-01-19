//
//  HomeView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/19/26.
//

import SwiftUI

struct HomeView: View {
    
    //    @Environment(\.di) var di
    @Environment(\.colorScheme) var color
    @State var viewModel = HomeViewModel()
    @State var selectedDate: Date = .init()
    @State var currentMonth: Date = .init()
    
    // MARK: - Constant
    private enum Constants {
        static let recentUpdateText: String = "최근 공지"
        static let scrollId: String = "scroll"
        static let listPadding: EdgeInsets = EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
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
            .toolbar {
                ToolBarCollection.BellBtn(action: { print("hello") })
                ToolBarCollection.Logo(
                    image: logImage,
                    action: {
                        withAnimation(.easeInOut(duration: DefaultConstant.animationTime)) {
                            proxy.scrollTo(Constants.scrollId, anchor: .top)
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - GenerationInfo
    
    /// 상단 기수 관련 정보 카드
    @ViewBuilder
    private var seasonCard: some View {
        HStack {
            ForEach(Array(viewModel.seasonData.enumerated()), id: \.offset) { index, season in
                SeasonCard(type: season)
                    .equatable()
            }
        }
    }
    
    // MARK: - Penalty
    
    /// 기수 별 패널티 정보
    @ViewBuilder
    private var generations: some View {
        PenaltyCard(generations: viewModel.generationData)
            .equatable()
    }
    
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
    
    // MARK: - Caneldar
    
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
        .padding(.vertical, DefaultSpacing.spacing32)
    }
    
    // MARK: - Recent
    private var recentUpdate: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4, content: {
            recentHeader
            sectionContent
        })
    }
    
    private var recentHeader: some View {
        Text(Constants.recentUpdateText)
            .appFont(.bodyEmphasis, color: .grey900)
    }
    
    private var sectionContent: some View {
        LazyVStack(spacing: 8) {
            ForEach(viewModel.recentNoticeData, id:\.id) { data in
                RecentNoticeCard(data: data)
            }
        }
    }
    
    // MARK: - Color {
    private var logImage: ImageResource {
        if color == .dark {
            return .logoDark
        } else {
            return .logoLight
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    //        .environment(DIContainer())
}
