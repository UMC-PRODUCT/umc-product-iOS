//
//  HomeViewModel.swift
//  AppProduct
//
//  Created by euijjang97 on 1/19/26.
//

import Foundation

/// 홈 화면의 전반적인 상태와 비즈니스 로직을 관리하는 뷰 모델입니다.
///
/// 기수 정보, 패널티 현황, 일정 데이터, 최근 공지사항 등을 관리하며
/// 뷰의 상태 변화를 트리거합니다.
@Observable
class HomeViewModel {
    
    // MARK: - Properties
    
    /// 기수 정보 데이터 (로딩 상태 포함)
    var seasonData: Loadable<[SeasonType]> = .loaded([
        .days(191),
        .gens([
            11, 12
        ])
    ])

    /// 기수별 패널티 정보 데이터 (로딩 상태 포함)
    var generationData: Loadable<[GenerationData]> = .loaded([
        GenerationData(
            gen: 11,
            penaltyPoint: 1,
            penaltyLogs: [
                .init(reason: "지각", date: "03.26", penaltyPoint: 1),
            ]
        ),
        GenerationData(
            gen: 12,
            penaltyPoint: 2,
            penaltyLogs: [
                .init(reason: "지각", date: "03.14", penaltyPoint: 1),
                .init(reason: "워크북 미제출", date: "03.16", penaltyPoint: 1),
                .init(reason: "행사 노쇼", date: "04.16", penaltyPoint: 1)
            ]
        )
    ])

    /// 날짜별 일정 데이터 딕셔너리
    /// - Key: 날짜 (Date)
    /// - Value: 해당 날짜의 일정 리스트 ([ScheduleData])
    var scheduleByDates: [Date: [ScheduleData]] = {
          let calendar = Calendar.current
          let today = calendar.startOfDay(for: .now)
                                                                                                                                                                                                                                                                                                                                                                                   
          return [
              today: [
                  .init(title: "데모데이", subTitle: "테스트")
              ]
          ]
      }()

    /// 최근 공지사항 데이터 (로딩 상태 포함)
    var recentNoticeData: Loadable<[RecentNoticeData]> = .loaded([
        .init(category: .oranization, title: "Web 파트 1회차 스터디 공지", createdAt: .now),
        .init(category: .oranization, title: "Web 파트 1회차 스터디 공지", createdAt: .now)
    ])

    /// 일정이 등록된 날짜들의 집합
    ///
    /// 캘린더 등에서 일정이 있는 날짜를 표시하기 위해 사용됩니다.
    var scheduleDates: Set<Date> {
        Set(scheduleByDates.keys)
    }

    // MARK: - Methods
    
    /// 특정 날짜에 해당하는 일정 목록을 반환합니다.
    ///
    /// 입력된 날짜를 정규화(해당 일의 00:00:00)하여 딕셔너리에서 조회합니다.
    ///
    /// - Parameter dat: 조회하려는 날짜
    /// - Returns: 해당 날짜의 일정 데이터 배열 (없으면 빈 배열 반환)
    func getShedules(_ dat: Date) -> [ScheduleData] {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: dat)
        return scheduleByDates[normalizedDate] ?? []
    }
}
