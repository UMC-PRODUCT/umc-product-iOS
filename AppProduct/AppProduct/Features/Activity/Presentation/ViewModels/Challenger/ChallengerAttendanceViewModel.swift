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

    /// 출석 가능 일정 목록
    private(set) var availableSchedules: Loadable<[AvailableAttendanceSchedule]> = .idle

    /// 내 출석 이력
    private(set) var myHistory: Loadable<[AttendanceHistoryItem]> = .idle

    /// 재시도 중 여부 (RetryContentUnavailableView용)
    private(set) var isRetrying: Bool = false

    private var statusObserver: (any NSObjectProtocol)?

    // MARK: - Init

    init(
        container: DIContainer,
        errorHandler: ErrorHandler,
        challengeAttendanceUseCase: ChallengerAttendanceUseCaseProtocol,
    ) {
        self.container = container
        self.errorHandler = errorHandler
        self.challengeAttendanceUseCase = challengeAttendanceUseCase
        observeAttendanceStatusChange()
    }

    deinit {
        if let observer = statusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Notification

    private func observeAttendanceStatusChange() {
        statusObserver = NotificationCenter.default.addObserver(
            forName: .attendanceStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refreshMyHistory()
            }
        }
    }

    /// 출석 이력 배경 갱신 (로딩 상태 변경 없이)
    @MainActor
    private func refreshMyHistory() async {
        guard !myHistory.isLoading else { return }
        do {
            let history = try await challengeAttendanceUseCase
                .fetchMyHistory()
            myHistory = .loaded(history)
        } catch {
            // 배경 갱신 실패는 무시
        }
    }

    // MARK: - Action

    /// 출석 가능 일정 조회
    @MainActor
    func fetchAvailableSchedules() async {
        availableSchedules = .loading
        do {
            let schedules = try await challengeAttendanceUseCase.fetchAvailableSchedules()
            availableSchedules = .loaded(schedules)
        } catch {
            availableSchedules = .failed(.unknown(
                message: error.localizedDescription
            ))
        }
    }

    /// 내 출석 이력 조회
    @MainActor
    func fetchMyHistory() async {
        myHistory = .loading
        do {
            let history = try await challengeAttendanceUseCase.fetchMyHistory()
            myHistory = .loaded(history)
        } catch {
            myHistory = .failed(.unknown(
                message: error.localizedDescription
            ))
        }
    }

    /// GPS 기반 출석 버튼 탭 처리
    @MainActor
    func attendanceBtnTapped(userId: UserID, session: Session, sheetId: Int) async {
        let info = session.info
        let timeWindow = currentTimeWindow(for: info)

        #if DEBUG
        print("[Attendance] attendanceBtnTapped called")
        print("[Attendance] timeWindow: \(timeWindow)")
        print("[Attendance] info.startTime: \(info.startTime)")
        print("[Attendance] now: \(Date())")
        #endif

        // .onTime = 정시 출석 가능 시간대
        guard timeWindow == .onTime else {
            #if DEBUG
            print("[Attendance] Guard failed - not in onTime window")
            #endif
            return
        }

        session.updateState(.loading)

        do {
            let result = try await challengeAttendanceUseCase.requestGPSAttendance(
                sessionId: info.sessionId, userId: userId, sheetId: sheetId)
            session.updateState(.loaded(result))
            session.markSubmitted()

        } catch let error as DomainError {
            session.updateState(.failed(.domain(error)))
        } catch {
            // 기타 에러 (네트워크 등) — 상태 복구 후 Alert
            if let prev = session.attendance {
                session.updateState(.loaded(prev))
            } else {
                session.updateState(.idle)
            }
            errorHandler.handle(error, context: .init(
                feature: "Activity",
                action: "attendanceBtnTapped",
                retryAction: { [weak self] in
                    await self?.attendanceBtnTapped(userId: userId, session: session, sheetId: sheetId)
                }
            ))
        }
    }

    /// 지각/결석 사유 제출 버튼 탭 처리
    @MainActor
    func attendanceReasonBtnTapped(
        userId: UserID,
        session: Session,
        reason: String,
        sheetId: Int
    ) async {
        let info = session.info
        let timeWindow = currentTimeWindow(for: info)
        guard timeWindow == .lateWindow || timeWindow == .expired else { return }

        session.updateState(.loading)

        do {
            let result = try await challengeAttendanceUseCase.submitLateReason(
                sessionId: info.sessionId, userId: userId, reason: reason, sheetId: sheetId)
            session.updateState(.loaded(result))

        } catch let error as DomainError {
            session.updateState(.failed(.domain(error)))
        } catch {
            // 기타 에러 (네트워크 등) — 상태 복구 후 Alert
            if let attendance = session.attendance {
                session.updateState(.loaded(attendance))
            } else {
                session.updateState(.idle)
            }
            errorHandler.handle(error, context: .init(
                feature: "Activity",
                action: "attendanceReasonBtnTapped",
                retryAction: { [weak self] in
                    await self?.attendanceReasonBtnTapped(
                        userId: userId,
                        session: session,
                        reason: reason,
                        sheetId: sheetId
                    )
                }
            ))
        }
    }

    /// 출석 사유 제출
    ///
    /// GPS 출석이 어려운 경우 사유를 제출합니다.
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - session: 출석 대상 세션
    ///   - reason: 출석 사유
    ///   - sheetId: 구글 시트 ID
    @MainActor
    func submitAttendanceReason(userId: UserID, session: Session, reason: String, sheetId: Int) async {
        let info = session.info
        session.updateState(.loading)

        do {
            let result = try await challengeAttendanceUseCase.submitLateReason(
                sessionId: info.sessionId,
                userId: userId,
                reason: reason,
                sheetId: sheetId
            )
            session.updateState(.loaded(result))
            session.markSubmitted()

        } catch let error as DomainError {
            session.updateState(.failed(.domain(error)))
        } catch {
            // 기타 에러 (네트워크 등) — 상태 복구 후 Alert
            if let prev = session.attendance {
                session.updateState(.loaded(prev))
            } else {
                session.updateState(.idle)
            }
            errorHandler.handle(error, context: .init(
                feature: "Activity",
                action: "submitAttendanceReason",
                retryAction: { [weak self] in
                    await self?.submitAttendanceReason(
                        userId: userId,
                        session: session,
                        reason: reason,
                        sheetId: sheetId
                    )
                }
            ))
        }
    }

    /// SessionID → sheetId 매핑 (available schedules 기반)
    func sheetId(for sessionId: SessionID) -> Int? {
        guard case .loaded(let schedules) = availableSchedules else {
            return nil
        }
        return schedules.first(where: {
            String($0.scheduleId) == sessionId.value
        })?.sheetId
    }

    func isAttendanceAvailable(for session: Session) -> Bool {
        session.canRequestAttendance(
            timeWindow: currentTimeWindow(for: session.info),
            isInsideGeofence: challengeAttendanceUseCase.isInsideGeofence,
            isLocationAuthorized: challengeAttendanceUseCase.isLocationAuthorized
        )
    }

    func buttonStyle(for session: Session) -> String {
        session.buttonTitle(
            isLocationAuthorized: challengeAttendanceUseCase.isLocationAuthorized,
            isInsideGeofence: challengeAttendanceUseCase.isInsideGeofence,
            timeWindow: challengeAttendanceUseCase.isWithinAttendanceTime(info: session.info)
        )
    }

    // MARK: - Helper Methods

    private func currentTimeWindow(for info: SessionInfo) -> AttendanceTimeWindow {
        challengeAttendanceUseCase.isWithinAttendanceTime(info: info)
    }

    // MARK: - Cleanup

    /// 지오펜스 모니터링 중지
    func geofenceCleanup() async {
        await challengeAttendanceUseCase.stopGeofenceMonitoring()
    }
}
