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

    // MARK: - Init

    init(
        container: DIContainer,
        errorHandler: ErrorHandler,
        challengeAttendanceUseCase: ChallengerAttendanceUseCaseProtocol,
    ) {
        self.container = container
        self.errorHandler = errorHandler
        self.challengeAttendanceUseCase = challengeAttendanceUseCase
    }

    // MARK: - Action

    /// GPS 기반 출석 버튼 탭 처리
    @MainActor
    func attendanceBtnTapped(userId: UserID, session: Session) async {
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
                sessionId: info.sessionId, userId: userId)
            session.updateState(.loaded(result))
            session.markSubmitted()

        } catch let error as DomainError {
            session.updateState(.failed(.domain(error)))
        } catch {
            // 기타 에러 (네트워크 등)
            if let prev = session.attendance {
                session.updateState(.loaded(prev))
            }
            errorHandler.handle(error, context: .init(
                feature: "Activity",
                action: "attendanceBtnTapped",
                retryAction: { [weak self] in
                    await self?.attendanceBtnTapped(userId: userId, session: session)
                }
            ))
        }
    }

    /// 지각/결석 사유 제출 버튼 탭 처리
    @MainActor
    func attendanceReasonBtnTapped(
        userId: UserID,
        session: Session,
        reason: String
    ) async {
        let info = session.info
        let timeWindow = currentTimeWindow(for: info)
        guard timeWindow == .lateWindow || timeWindow == .expired else { return }

        session.updateState(.loading)

        do {
            let result = try await challengeAttendanceUseCase.submitLateReason(
                sessionId: info.sessionId, userId: userId, reason: reason)
            session.updateState(.loaded(result))

        } catch let error as DomainError {
            session.updateState(.failed(.domain(error)))
        } catch {
            // 기타 에러 (네트워크 등)
            if let attendance = session.attendance {
                session.updateState(.loaded(attendance))
            }
            errorHandler.handle(error, context: .init(
                feature: "Activity",
                action: "attendanceReasonBtnTapped",
                retryAction: { [weak self] in
                    await self?.attendanceReasonBtnTapped(
                        userId: userId,
                        session: session,
                        reason: reason
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
    @MainActor
    func submitAttendanceReason(userId: UserID, session: Session, reason: String) async {
        let info = session.info
        session.updateState(.loading)

        do {
            let result = try await challengeAttendanceUseCase.submitLateReason(
                sessionId: info.sessionId,
                userId: userId,
                reason: reason
            )
            session.updateState(.loaded(result))
            session.markSubmitted()

        } catch let error as DomainError {
            session.updateState(.failed(.domain(error)))
        } catch {
            if let prev = session.attendance {
                session.updateState(.loaded(prev))
            }
            errorHandler.handle(error, context: .init(
                feature: "Activity",
                action: "submitAttendanceReason",
                retryAction: { [weak self] in
                    await self?.submitAttendanceReason(
                        userId: userId,
                        session: session,
                        reason: reason
                    )
                }
            ))
        }
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
