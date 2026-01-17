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
    
    func isAttendanceAvailable(for session: Session) -> Bool {
        currentTimeWindow(for: session.info) == .onTime
        && challengeAttendanceUseCase.isInsideGeofence
        && challengeAttendanceUseCase.isLocationAuthorized
        && !session.isLoading
        && !session.hasSubmitted
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
}
