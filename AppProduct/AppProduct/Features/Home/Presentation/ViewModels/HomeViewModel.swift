//
//  HomeViewModel.swift
//  AppProduct
//
//  Created by euijjang97 on 1/19/26.
//

import Foundation

@Observable
class HomeViewModel {
    var seasonData: [SeasonType] = [
        .days(365),
        .gens([10, 11, 12, 13])
    ]

    var generationData: [GenerationData] = [
        GenerationData(
            gen: 10,
            penaltyPoint: 1,
            penaltyLogs: [
                PenaltyInfoItem(reason: "세션 지각", date: "2024.03.15", penaltyPoint: 2),
                PenaltyInfoItem(reason: "과제 미제출", date: "2024.03.20", penaltyPoint: 3)
            ]
        ),
        GenerationData(
            gen: 11,
            penaltyPoint: 2,
            penaltyLogs: [
                PenaltyInfoItem(reason: "세션 결석", date: "2024.09.10", penaltyPoint: 3)
            ]
        ),
        GenerationData(
            gen: 12,
            penaltyPoint: 3,
            penaltyLogs: [
                PenaltyInfoItem(reason: "워크북 미제출", date: "2025.03.05", penaltyPoint: 3),
                PenaltyInfoItem(reason: "세션 지각", date: "2025.04.12", penaltyPoint: 2),
                PenaltyInfoItem(reason: "스터디 불참", date: "2025.05.01", penaltyPoint: 3)
            ]
        ),
        GenerationData(
            gen: 13,
            penaltyPoint: 0,
            penaltyLogs: []
        )
    ]

    var scheduleByDates: [Date: [ScheduleData]] = {
        let calendar = Calendar.current
        var schedules: [Date: [ScheduleData]] = [:]

        // 2026년 1월 19일
        if let date1 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 19)) {
            let normalizedDate = calendar.startOfDay(for: date1)
            schedules[normalizedDate] = [
                ScheduleData(title: "UMC 전체 세션", subTitle: "오후 2시 | 강남역 스터디룸"),
                ScheduleData(title: "파트별 스터디", subTitle: "오후 6시 | 온라인")
            ]
        }

        // 2026년 1월 21일
        if let date2 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 21)) {
            let normalizedDate = calendar.startOfDay(for: date2)
            schedules[normalizedDate] = [
                ScheduleData(title: "회비 납부 마감일", subTitle: "자정까지 | 계좌이체"),
                ScheduleData(title: "워크북 제출", subTitle: "오후 11시 59분 | 구글 클래스룸")
            ]
        }

        // 2026년 1월 25일
        if let date3 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 25)) {
            let normalizedDate = calendar.startOfDay(for: date3)
            schedules[normalizedDate] = [
                ScheduleData(title: "데모데이", subTitle: "오후 1시 | 코엑스 컨퍼런스룸"),
                ScheduleData(title: "네트워킹 행사", subTitle: "오후 5시 | 강남역 근처"),
                ScheduleData(title: "회고 세션", subTitle: "오후 7시 | 온라인")
            ]
        }

        // 2026년 1월 27일
        if let date4 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 27)) {
            let normalizedDate = calendar.startOfDay(for: date4)
            schedules[normalizedDate] = [
                ScheduleData(title: "해커톤 시작", subTitle: "오전 10시 | 선릉역 D2 스타트업 팩토리")
            ]
        }

        // 2026년 1월 30일
        if let date5 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 30)) {
            let normalizedDate = calendar.startOfDay(for: date5)
            schedules[normalizedDate] = [
                ScheduleData(title: "프로젝트 중간 발표", subTitle: "오후 3시 | 온라인 Zoom")
            ]
        }

        return schedules
    }()

    var recentNoticeData: [RecentNoticeData] = [
        RecentNoticeData(
            category: .operationsTeam,
            title: "14기 모집 공고 안내",
            createdAt: .now
        )
    ]

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
