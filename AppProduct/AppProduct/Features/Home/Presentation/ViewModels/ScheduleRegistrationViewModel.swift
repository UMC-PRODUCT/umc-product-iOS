//
//  ScheduleRegistrationViewModel.swift
//  AppProduct
//
//  Created by euijjang97 on 1/22/26.
//

import Foundation

/// 일정 등록 화면의 비즈니스 로직을 담당하는 뷰 모델입니다.
///
/// 제목, 장소, 시간, 참여자 등 일정 입력 폼의 상태를 관리합니다.
@Observable
class ScheduleRegistrationViewModel {
    // MARK: - Property
    
    /// 입력된 일정 제목
    var title: String = ""
    
    /// 선택된 장소 정보 (이름, 주소, 좌표)
    var place: PlaceSearchInfo = .init(name: "", address: "", coordinate: .init(latitude: 0.0, longitude: 0.0))
    
    /// 하루 종일 일정 여부 토글 상태
    var isAllDay: Bool = false
    
    /// 선택된 날짜 범위 (시작일~종료일)
    /// 기본값: 현재 시간 + 1시간부터 + 2시간까지
    var dataRange: DateRange = .init(startDate: .now.addingTimeInterval(3600), endDate: .now.addingTimeInterval(7200))
    
    /// 시작 날짜 DatePicker 표시 여부
    var showStartDatePicker: Bool = false
    
    /// 시작 시간 DatePicker 표시 여부
    var showStartTimePicker: Bool = false
    
    /// 종료 날짜 DatePicker 표시 여부
    var showEndDatePicker: Bool = false
    
    /// 종료 시간 DatePicker 표시 여부
    var showEndTimePicker: Bool = false
    
    /// 추가 메모 사항
    var memo: String = ""
    
    /// 선택된 참여자 목록
    var participatn: [ChallengerInfo] = .init()
    
    /// 선택된 카테고리 태그 목록
    var tag: [ScheduleIconCategory] = .init()
}
