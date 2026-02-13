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

    /// 일정 생성 UseCase
    private let generateScheduleUseCase: GenerateScheduleUseCaseProtocol

    /// 전역 에러 핸들러 (실패 시 Alert 표시용)
    private let errorHandler: ErrorHandler

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

    /// 일정 생성 API 상태 (로딩 overlay + 성공 시 dismiss 제어)
    private(set) var submitState: Loadable<Bool> = .idle

    /// 출석부 포함 여부 확인 Alert 데이터
    var alertPrompt: AlertPrompt?

    // MARK: - Init

    init(container: DIContainer, errorHandler: ErrorHandler) {
        let provider = container.resolve(HomeUseCaseProviding.self)
        self.generateScheduleUseCase = provider.generateScheduleUseCase
        self.errorHandler = errorHandler
    }

    // MARK: - Function

    /// 일정을 서버에 생성합니다.
    ///
    /// - Parameters:
    ///   - gisuId: 기수 식별 ID
    ///   - requiresApproval: 출석부 동시 생성 여부 (true: 출석부 포함)
    ///
    /// - Note: 실패 시 `ErrorHandler`를 통해 전역 Alert을 표시하며,
    ///   재시도 버튼이 포함됩니다.
    @MainActor
    func submitSchedule(gisuId: Int, requiresApproval: Bool) async {
        submitState = .loading
        var memberIds = participatn.map(\.memberId)
        let myMemberId = UserDefaults.standard.integer(forKey: AppStorageKey.memberId)
        if myMemberId != 0, !memberIds.contains(myMemberId) {
            memberIds.append(myMemberId)
        }
        let dto = GenerateScheduleRequetDTO(
            name: title,
            startsAt: dataRange.startDate,
            endsAt: dataRange.endDate,
            isAllDay: isAllDay,
            locationName: place.name,
            latitude: place.coordinate.latitude,
            longitude: place.coordinate.longitude,
            description: memo,
            participantMemberIds: memberIds,
            tags: tag,
            gisuId: gisuId,
            requiresApproval: requiresApproval
        )
        do {
            try await generateScheduleUseCase.execute(schedule: dto)
            submitState = .loaded(true)
        } catch {
            submitState = .idle
            errorHandler.handle(error, context: ErrorContext(
                feature: "Home",
                action: "submitSchedule",
                retryAction: { [weak self] in
                    await self?.submitSchedule(
                        gisuId: gisuId, requiresApproval: requiresApproval
                    )
                }
            ))
        }
    }
    
    /// 운영진용 일정 생성 Alert을 표시합니다.
    ///
    /// 출석부 동시 생성 여부를 선택하는 3버튼 Alert을 띄웁니다.
    /// - Parameter gisuId: 기수 식별 ID
    func alertAction(gisuId: Int) {
        alertPrompt = AlertPrompt(
            title: "일정 생성",
            message: "출석부도 함께 생성하시겠습니까?",
            positiveBtnTitle: "출석부도 같이 생성할게요",
            positiveBtnAction: { [weak self] in
                Task { @MainActor in
                    await self?.submitSchedule(
                        gisuId: gisuId, requiresApproval: true
                    )
                }
            },
            secondaryBtnTitle: "아니요 일정만 생성할게",
            secondaryBtnAction: { [weak self] in
                Task { @MainActor in
                    await self?.submitSchedule(
                        gisuId: gisuId, requiresApproval: false
                    )
                }
            },
            negativeBtnTitle: "취소"
        )
    }
}
