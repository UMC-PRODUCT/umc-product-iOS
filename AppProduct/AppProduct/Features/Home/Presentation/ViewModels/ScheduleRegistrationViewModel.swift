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
    /// 일정 수정 UseCase
    private let updateScheduleUseCase: UpdateScheduleUseCaseProtocol

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
    /// 수정 모드일 때 대상 일정 ID
    private(set) var editingScheduleId: Int?
    /// 수정 모드 초기값 스냅샷
    private var initialEditSnapshot: EditFormSnapshot?

    // MARK: - Init

    init(container: DIContainer, errorHandler: ErrorHandler) {
        let provider = container.resolve(HomeUseCaseProviding.self)
        self.generateScheduleUseCase = provider.generateScheduleUseCase
        self.updateScheduleUseCase = provider.updateScheduleUseCase
        self.errorHandler = errorHandler
    }

    // MARK: - Prefill

    /// 일정 상세 데이터를 기반으로 등록 폼을 프리필합니다.
    func applyPrefill(from detail: ScheduleDetailData, roadAddress: String?) {
        editingScheduleId = detail.scheduleId
        title = detail.name
        memo = detail.description
        isAllDay = detail.isAllDay
        dataRange = DateRange(startDate: detail.startsAt, endDate: detail.endsAt)
        place = PlaceSearchInfo(
            name: detail.locationName,
            address: roadAddress ?? detail.locationName,
            coordinate: Coordinate(
                latitude: detail.latitude,
                longitude: detail.longitude
            )
        )
        tag = detail.tags.compactMap(Self.mapScheduleTag)
        initialEditSnapshot = currentEditSnapshot
    }

    /// 서버 태그 문자열을 `ScheduleIconCategory`로 매핑합니다.
    ///
    /// rawValue 직접 매핑 → 대문자 변환 매핑 → 한글 매핑 순으로 시도합니다.
    nonisolated private static func mapScheduleTag(_ raw: String) -> ScheduleIconCategory? {
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let direct = ScheduleIconCategory(rawValue: normalized) {
            return direct
        }
        if let upper = ScheduleIconCategory(rawValue: normalized.uppercased()) {
            return upper
        }
        switch normalized {
        case "리더십": return .leadership
        case "스터디": return .study
        case "회비": return .fee
        case "회의": return .meeting
        case "네트워킹": return .networking
        case "해커톤": return .hackathon
        case "프로젝트": return .project
        case "발표": return .presentation
        case "워크샵": return .workshop
        case "회고": return .review
        case "뒷풀이": return .celebration
        case "오리엔테이션": return .orientation
        case "테스트": return .testing
        case "일반": return .general
        default: return nil
        }
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
        var memberIds = Array(Set(participatn.map(\.memberId))).sorted()
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

    /// 수정 모드에서 초기값 대비 변경 사항이 있는지 확인합니다.
    var hasChangesInEditMode: Bool {
        guard initialEditSnapshot != nil else { return true }
        return initialEditSnapshot != currentEditSnapshot
    }

    /// 현재 폼 상태의 스냅샷을 생성합니다.
    private var currentEditSnapshot: EditFormSnapshot {
        EditFormSnapshot(
            title: title,
            placeName: place.name,
            placeAddress: place.address,
            latitude: place.coordinate.latitude,
            longitude: place.coordinate.longitude,
            isAllDay: isAllDay,
            startDate: dataRange.startDate,
            endDate: dataRange.endDate,
            memo: memo,
            participantMemberIds: Array(Set(participatn.map(\.memberId))).sorted(),
            tags: tag.map(\.rawValue).sorted()
        )
    }

    /// 수정 모드에서 변경 감지를 위한 폼 상태 스냅샷
    private struct EditFormSnapshot: Equatable {
        let title: String
        let placeName: String
        let placeAddress: String
        let latitude: Double
        let longitude: Double
        let isAllDay: Bool
        let startDate: Date
        let endDate: Date
        let memo: String
        let participantMemberIds: [Int]
        let tags: [String]
    }

    /// 일정을 서버에 수정합니다.
    @MainActor
    func updateSchedule() async {
        guard let scheduleId = editingScheduleId else {
            return
        }

        submitState = .loading
        var participantMemberIds: [Int]? = nil
        if !participatn.isEmpty {
            participantMemberIds = Array(Set(participatn.map(\.memberId))).sorted()
        }
        let dto = UpdateScheduleRequestDTO(
            name: title,
            startsAt: dataRange.startDate,
            endsAt: dataRange.endDate,
            isAllDay: isAllDay,
            locationName: place.name,
            latitude: place.coordinate.latitude,
            longitude: place.coordinate.longitude,
            description: memo,
            tags: tag,
            participantMemberIds: participantMemberIds
        )
        do {
            try await updateScheduleUseCase.execute(
                scheduleId: scheduleId,
                schedule: dto
            )
            submitState = .loaded(true)
        } catch {
            submitState = .idle
            errorHandler.handle(error, context: ErrorContext(
                feature: "Home",
                action: "updateSchedule",
                retryAction: { [weak self] in
                    await self?.updateSchedule()
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
