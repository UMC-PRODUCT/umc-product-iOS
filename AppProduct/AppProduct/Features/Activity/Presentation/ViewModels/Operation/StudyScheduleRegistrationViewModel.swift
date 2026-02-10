//
//  StudyScheduleRegistrationViewModel.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/10/26.
//

import Foundation

/// 스터디 일정 등록 화면의 상태를 관리하는 뷰 모델
@Observable
final class StudyScheduleRegistrationViewModel {

    // MARK: - Property

    /// 스터디명 (초기값은 스터디 그룹 이름)
    var studyName: String

    /// 시작 일시
    var startDate: Date = .now.addingTimeInterval(3600)

    /// 종료 일시
    var endDate: Date = .now.addingTimeInterval(7200)

    /// 장소
    var location: String = ""

    // MARK: - DatePicker Toggle State

    var showStartDatePicker = false
    var showStartTimePicker = false
    var showEndDatePicker = false
    var showEndTimePicker = false

    // MARK: - Computed Property

    /// 등록 버튼 활성화 여부
    var canSubmit: Bool {
        !studyName.trimmingCharacters(in: .whitespaces).isEmpty
            && !location.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Init

    init(studyName: String) {
        self.studyName = studyName
    }
}
