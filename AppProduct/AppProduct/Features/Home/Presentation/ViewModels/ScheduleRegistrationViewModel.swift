//
//  ScheduleRegistrationViewModel.swift
//  AppProduct
//
//  Created by euijjang97 on 1/22/26.
//

import Foundation

/// 일정 등록 화면의 비즈니스 로직을 담당하는 뷰 모델
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
    /// 시작 날짜 선택기 표시 여부
    var showStartDatePicker: Bool = false
    /// 시작 시간 선택기 표시 여부
    var showStartTimePicker: Bool = false
    /// 종료 날짜 선택기 표시 여부
    var showEndDatePicker: Bool = false
    /// 종료 시간 선택기 표시 여부
    var showEndTimePicker: Bool = false
    
    /// 메모
    var memo: String = ""
    /// 참여자 명단
    var participatn: Participant?
    /// 태그
    var tag: ScheduleIconCategory?
    
}
