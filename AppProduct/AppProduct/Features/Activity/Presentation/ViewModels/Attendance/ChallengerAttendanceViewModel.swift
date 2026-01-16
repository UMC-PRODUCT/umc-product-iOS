//
//  ChallengerAttendanceViewModel.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/15/26.
//

import Foundation

/// 챌린저(일반 참여자)의 출석 관련 상태 및 액션을 관리하는 ViewModel
@Observable
final class ChallengerAttendanceViewModel {
    private var container: DIContainer
    private var errorHandler: ErrorHandler
    private var challengeAttendanceUseCase: ChallengerAttendanceUseCaseProtocol

    private(set) var currentSession: Session
    
    /// 이번 세션에서 출석을 제출했는지 여부
    private(set) var hasSubmittedThisSession: Bool = false

    /// 출석 요청 상태 (idle → loading → loaded/failed)
    private(set) var attendanceState: Loadable<Attendance>

    // MARK: - Computed Property

    /// 출석 상태
    var attendanceStatusState: Loadable<AttendanceStatus> {
        attendanceState.map { $0.status }
    }

    /// 출석 타입
    var attendanceTypeState: Loadable<AttendanceType> {
        attendanceState.map { $0.type }
    }

    /// 현재 시간대 상태
    var currentTimeWindow: AttendanceTimeWindow {
        challengeAttendanceUseCase.isWithinAttendanceTime(session: currentSession)
    }

    /// 이미 출석을 제출했는지 여부 (Loadable 상태 기반)
    var isAlreadySubmitted: Bool {
        guard case .loaded(let attendance) = attendanceState else { return false }
        return hasSubmittedThisSession || attendance.status != .pending
    }

    /// 출석 버튼 활성화 조건 (Loadable 상태 기반)
    var isAttendanceAvailable: Bool {
        currentTimeWindow == .onTime &&
        challengeAttendanceUseCase.isInsideGeofence &&
        challengeAttendanceUseCase.isLocationAuthorized &&
        !attendanceState.isLoading &&
        !isAlreadySubmitted
    }

    /// 버튼 타이틀 (Loadable 상태별 분기)
    var buttonTitle: String {
        // 로딩 상태
        if attendanceState.isLoading {
            return "출석 처리 중..."
        }

        // 에러 상태
        if attendanceState.error != nil {
            return "다시 시도하기"
        }

        // 로드 완료 상태
        if case .loaded(let attendance) = attendanceState {
            // 이번 세션에서 제출함 + 아직 pending → 승인 대기
            if hasSubmittedThisSession, attendance.status == .pending {
                return "승인 대기 중"
            }

            // 최종 결정됨 (출석 / 지각 / 결석)
            if attendance.status != .pending {
                return attendance.status.displayText
            }
        }

        // 시간대 체크
        switch currentTimeWindow {
        case .tooEarly:
            return "아직 출석 시간이 아닙니다"
        case .lateWindow:
            return "지각 - 사유를 제출하세요"
        case .expired:
            return "출석 마감됨"
        case .onTime:
            break  // 아래 조건들 계속 체크
        }

        // 위치 권한 체크
        if !challengeAttendanceUseCase.isLocationAuthorized {
            return "위치 권한 필요"
        }

        // 지오펜스 체크
        if !challengeAttendanceUseCase.isInsideGeofence {
            return "출석 범위 밖"
        }

        return "현 위치로 출석체크"
    }

    #if DEBUG
    /// 테스트용 상태 변경
    func simulateApproval(_ status: AttendanceStatus) {
        guard case .loaded(let attendance) = attendanceState else { return }
        let updated = attendance.rejected(status: status)
        attendanceState = .loaded(updated)
    }

    func simulateError(_ error: AppError) {
        attendanceState = .failed(error)
    }
    #endif

    // MARK: - Private

    private let initialAttendance: Attendance

    // MARK: - Init

    init(
        container: DIContainer,
        errorHandler: ErrorHandler,
        challengeAttendanceUseCase: ChallengerAttendanceUseCaseProtocol,
        session: Session,
        attendance: Attendance
    ) {
        self.container = container
        self.errorHandler = errorHandler
        self.challengeAttendanceUseCase = challengeAttendanceUseCase
        self.currentSession = session
        self.initialAttendance = attendance
        self.attendanceState = .loaded(attendance)
    }

    // MARK: - Action

    /// GPS 기반 출석 버튼 탭 처리
    @MainActor
    func attendanceBtnTapped(userId: UserID) async {
        let timeWindow = challengeAttendanceUseCase.isWithinAttendanceTime(session: currentSession)

        #if DEBUG
        print("[Attendance] attendanceBtnTapped called")
        print("[Attendance] timeWindow: \(timeWindow)")
        print("[Attendance] session.startTime: \(currentSession.startTime)")
        print("[Attendance] now: \(Date())")
        #endif

        // .onTime = 정시 출석 가능 시간대
        guard timeWindow == .onTime else {
            #if DEBUG
            print("[Attendance] Guard failed - not in onTime window")
            #endif
            return
        }

        attendanceState = .loading

        do {
            let result = try await challengeAttendanceUseCase.requestGPSAttendance(
                sessionId: currentSession.sessionId, userId: userId)
            attendanceState = .loaded(result)
            hasSubmittedThisSession = true

        } catch let error as DomainError {
            attendanceState = .failed(.domain(error))
        } catch {
            // 기타 에러 (네트워크 등)
            attendanceState = .loaded(initialAttendance)
            errorHandler.handle(error, context: .init(
                feature: "Activity",
                action: "attendanceBtnTapped",
                retryAction: { [weak self] in
                    await self?.attendanceBtnTapped(userId: userId)
                }
            ))
        }
    }

    /// 지각/결석 사유 제출 버튼 탭 처리
    @MainActor
    func attendanceReasonBtnTapped(userId: UserID, reason: String) async {
        let timeWindow = challengeAttendanceUseCase.isWithinAttendanceTime(session: currentSession)
        guard timeWindow == .lateWindow || timeWindow == .expired else { return }

        attendanceState = .loading

        do {
            let result = try await challengeAttendanceUseCase.submitLateReason(
                sessionId: currentSession.sessionId, userId: userId, reason: reason)
            attendanceState = .loaded(result)
            hasSubmittedThisSession = true

        } catch let error as DomainError {
            attendanceState = .failed(.domain(error))

        } catch {
            // 기타 에러 (네트워크 등)
            attendanceState = .loaded(initialAttendance)
            errorHandler.handle(error, context: .init(
                feature: "Activity",
                action: "attendanceReasonBtnTapped",
                retryAction: { [weak self] in
                    await self?.attendanceReasonBtnTapped(userId: userId, reason: reason)
                }
            ))
        }
    }
}
