//
//  HomeViewModel.swift
//  AppProduct
//
//  Created by euijjang97 on 1/19/26.
//

import Foundation

@Observable
class HomeViewModel {
    var seasonData: Loadable<[SeasonType]> = .loading

    var generationData: Loadable<[GenerationData]> = .loading

    var scheduleByDates: [Date: [ScheduleData]] = .init()

    var recentNoticeData: Loadable<[RecentNoticeData]> = .loading

    var scheduleDates: Set<Date> {
        Set(scheduleByDates.keys)
    }

    // MARK: - Method
    func getShedules(_ dat: Date) -> [ScheduleData] {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: dat)
        return scheduleByDates[normalizedDate] ?? []
    }
}
