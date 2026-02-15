//
//  HomeDebugScheme.swift
//  AppProduct
//
//  Created by euijjang97 on 2/16/26.
//

import Foundation

#if DEBUG
enum HomeDebugState: String {
    case loading
    case loaded
    case failed

    static func fromLaunchArgument() -> HomeDebugState? {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-homeDebugState"),
           arguments.indices.contains(index + 1) {
            return HomeDebugState(rawValue: arguments[index + 1])
        }

        if let environmentValue = ProcessInfo.processInfo.environment["HOME_DEBUG_STATE"] {
            return HomeDebugState(rawValue: environmentValue)
        }

        return nil
    }

    func apply(to viewModel: HomeViewModel, selectedDate: Date) {
        viewModel.seedForDebugState(
            seasonData: seasonLoadable,
            generationData: generationLoadable,
            recentNoticeData: noticeLoadable,
            scheduleByDates: schedules(selectedDate: selectedDate)
        )
    }

    private var seasonLoadable: Loadable<[SeasonType]> {
        switch self {
        case .loading:
            return .loading
        case .loaded:
            return .loaded([.days(42), .gens([1, 2])])
        case .failed:
            return .failed(.unknown(message: "기수 데이터를 불러오지 못했습니다."))
        }
    }

    private var generationLoadable: Loadable<[GenerationData]> {
        switch self {
        case .loading:
            return .loading
        case .loaded:
            return .loaded([
                GenerationData(
                    gisuId: 101,
                    gen: 1,
                    penaltyPoint: 1,
                    penaltyLogs: [
                        PenaltyInfoItem(
                            reason: "지각",
                            date: "2026.01.10",
                            penaltyPoint: 1
                        )
                    ]
                ),
                GenerationData(
                    gisuId: 102,
                    gen: 2,
                    penaltyPoint: 0,
                    penaltyLogs: []
                )
            ])
        case .failed:
            return .failed(.unknown(message: "패널티 데이터를 불러오지 못했습니다."))
        }
    }

    private var noticeLoadable: Loadable<[RecentNoticeData]> {
        switch self {
        case .loading:
            return .loading
        case .loaded:
            return .loaded([
                RecentNoticeData(
                    category: .operationsTeam,
                    title: "2기 OT 공지",
                    createdAt: .now
                ),
                RecentNoticeData(
                    category: .univ,
                    title: "학교별 스터디 모집 안내",
                    createdAt: .now.addingTimeInterval(-86_400)
                )
            ])
        case .failed:
            return .failed(.unknown(message: "최근 공지를 불러오지 못했습니다."))
        }
    }

    private func schedules(selectedDate: Date) -> [Date: [ScheduleData]] {
        guard self == .loaded else { return [:] }
        let normalizedDate = Calendar.current.startOfDay(for: selectedDate)
        return [
            normalizedDate: [
                ScheduleData(
                    scheduleId: 1,
                    title: "UMC 정기 세션",
                    startsAt: selectedDate,
                    endsAt: selectedDate.addingTimeInterval(3_600),
                    status: "참여 예정",
                    dDay: 0
                )
            ]
        ]
    }
}

#endif
