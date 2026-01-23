//
//  ScheduleRegistrationViewModel.swift
//  AppProduct
//
//  Created by euijjang97 on 1/22/26.
//

import Foundation

@Observable
class ScheduleRegistrationViewModel {
    // MARK: - Property
    /// 일정 제목
    var title: String = ""
    /// 장소
    var place: PlaceSearchInfo = .init(name: "", address: "", coordinate: .init(latitude: 0.0, longitude: 0.0))
    /// 하루 종일 토글
    var isAllDay: Bool = false
    /// 시작 날짜 및 종료 날짜
    var dataRange: DateRange = .init(startDate: .now.addingTimeInterval(3600), endDate: .now.addingTimeInterval(7200))
    /// 메모
    var memo: String = ""
    /// 참여자 명단
    var participatn: Participant?
    /// 태그
    var tag: ScheduleIconCategory?

}
