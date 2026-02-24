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

    // MARK: - Dependency

    private let useCase: FetchStudyMembersUseCaseProtocol
    private let errorHandler: ErrorHandler
    private let studyGroupId: Int

    // MARK: - Property

    /// 선택된 장소
    var place: PlaceSearchInfo = .init(name: "", address: "", coordinate: .init(latitude: 0.0, longitude: 0.0))
    
    /// 스터디명 (초기값은 스터디 그룹 이름)
    var studyName: String

    /// 시작 일시
    var startDate: Date = .now.addingTimeInterval(3600)

    /// 종료 일시
    var endDate: Date = .now.addingTimeInterval(7200)

    // MARK: - DatePicker Toggle State

    /// 시작 날짜 DatePicker 표시 여부
    var showStartDatePicker = false
    /// 시작 시간 DatePicker 표시 여부
    var showStartTimePicker = false
    /// 종료 날짜 DatePicker 표시 여부
    var showEndDatePicker = false
    /// 종료 시간 DatePicker 표시 여부
    var showEndTimePicker = false

    // MARK: - Computed Property

    /// 등록 버튼 활성화 여부
    var canSubmit: Bool {
        !studyName.trimmingCharacters(in: .whitespaces).isEmpty
            && !place.name.trimmingCharacters(in: .whitespaces).isEmpty
            && studyGroupId > 0
            && endDate >= startDate
    }

    /// 스케줄 등록 실행
    @MainActor
    func submitSchedule() async -> Bool {
        guard canSubmit else {
            return false
        }

        let gisuId = UserDefaults.standard.integer(forKey: AppStorageKey.gisuId)
        guard gisuId > 0 else {
            return false
        }

        do {
            try await useCase.createStudyGroupSchedule(
                name: studyName.trimmingCharacters(in: .whitespacesAndNewlines),
                startsAt: startDate,
                endsAt: endDate,
                isAllDay: false,
                locationName: place.name,
                latitude: place.coordinate.latitude,
                longitude: place.coordinate.longitude,
                description: "",
                studyGroupId: studyGroupId,
                gisuId: gisuId,
                requiresApproval: true
            )
            return true
        } catch {
            errorHandler.handle(error, context: ErrorContext(
                feature: "Activity",
                action: "createStudyGroupSchedule",
                retryAction: { [weak self] in
                    _ = await self?.submitSchedule()
                }
            ))
            return false
        }
    }

    // MARK: - Init

    /// - Parameters:
    ///   - studyName: 스터디 그룹 이름 (초기값)
    ///   - studyGroupId: 스터디 그룹 식별자
    ///   - useCase: 스터디 관리 UseCase
    ///   - errorHandler: 전역 에러 핸들러
    init(
        studyName: String,
        studyGroupId: Int,
        useCase: FetchStudyMembersUseCaseProtocol,
        errorHandler: ErrorHandler
    ) {
        self.studyName = studyName
        self.studyGroupId = studyGroupId
        self.useCase = useCase
        self.errorHandler = errorHandler
    }
}
