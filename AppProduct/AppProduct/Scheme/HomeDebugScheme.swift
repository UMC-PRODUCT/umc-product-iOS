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
            return .loaded([.days(138), .gens([8, 9, 10])])
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
                    gisuId: 901,
                    gen: 9,
                    penaltyPoint: 1,
                    penaltyLogs: [
                        PenaltyInfoItem(
                            reason: "세션 지각",
                            date: "2026.01.08",
                            penaltyPoint: 1
                        )
                    ]
                ),
                GenerationData(
                    gisuId: 1001,
                    gen: 10,
                    penaltyPoint: 2,
                    penaltyLogs: [
                        PenaltyInfoItem(
                            reason: "과제 지연 제출",
                            date: "2026.01.20",
                            penaltyPoint: 1
                        ),
                        PenaltyInfoItem(
                            reason: "출석 미체크",
                            date: "2026.02.03",
                            penaltyPoint: 1
                        )
                    ]
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
                    title: "[필독] 10기 정규 세션 운영 가이드 안내",
                    createdAt: .now.addingTimeInterval(-3_600)
                ),
                RecentNoticeData(
                    category: .univ,
                    title: "가천대학교 iOS 파트 스터디룸 변경 공지",
                    createdAt: .now.addingTimeInterval(-86_400)
                ),
                RecentNoticeData(
                    category: .oranization,
                    title: "Nova 지부 네트워킹 데이 참가 신청",
                    createdAt: .now.addingTimeInterval(-172_800)
                )
            ])
        case .failed:
            return .failed(.unknown(message: "최근 공지를 불러오지 못했습니다."))
        }
    }

    private func schedules(selectedDate: Date) -> [Date: [ScheduleData]] {
        guard self == .loaded else { return [:] }
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: selectedDate)
        let morningSessionStart = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        let eveningStudyStart = calendar.date(bySettingHour: 19, minute: 30, second: 0, of: selectedDate) ?? selectedDate
        let nextDay = calendar.date(byAdding: .day, value: 1, to: normalizedDate) ?? normalizedDate

        return [
            normalizedDate: [
                ScheduleData(
                    scheduleId: 1,
                    title: "UMC 중앙 정기 세션",
                    startsAt: morningSessionStart,
                    endsAt: morningSessionStart.addingTimeInterval(7_200),
                    status: "참여 예정",
                    dDay: 0
                ),
                ScheduleData(
                    scheduleId: 2,
                    title: "iOS 파트 코드리뷰 스터디",
                    startsAt: eveningStudyStart,
                    endsAt: eveningStudyStart.addingTimeInterval(5_400),
                    status: "참여 완료",
                    dDay: 0
                )
            ],
            nextDay: [
                ScheduleData(
                    scheduleId: 3,
                    title: "지부 네트워킹 행사",
                    startsAt: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: nextDay) ?? nextDay,
                    endsAt: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: nextDay) ?? nextDay,
                    status: "참여 예정",
                    dDay: 1
                )
            ]
        ]
    }
}

#endif
