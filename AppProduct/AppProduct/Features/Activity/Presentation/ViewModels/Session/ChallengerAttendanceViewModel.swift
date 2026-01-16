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
    func attendanceBtnTapped(userId: UserID, sessionItem: SessionItem) async {
        let session = sessionItem.session
        let timeWindow = currentTimeWindow(for: session)

        #if DEBUG
        print("[Attendance] attendanceBtnTapped called")
        print("[Attendance] timeWindow: \(timeWindow)")
        print("[Attendance] session.startTime: \(session.startTime)")
        print("[Attendance] now: \(Date())")
        #endif

        // .onTime = 정시 출석 가능 시간대
        guard timeWindow == .onTime else {
            #if DEBUG
            print("[Attendance] Guard failed - not in onTime window")
            #endif
            return
        }

        sessionItem.updateState(.loading)

        do {
            let result = try await challengeAttendanceUseCase.requestGPSAttendance(
                sessionId: session.sessionId, userId: userId)
            sessionItem.updateState(.loaded(result))

        } catch let error as DomainError {
            sessionItem.updateState(.failed(.domain(error)))
        } catch {
            // 기타 에러 (네트워크 등)
            if let prev = sessionItem.attendance {
                sessionItem.updateState(.loaded(prev))
            }
            errorHandler.handle(error, context: .init(
                feature: "Activity",
                action: "attendanceBtnTapped",
                retryAction: { [weak self] in
                    await self?.attendanceBtnTapped(userId: userId, sessionItem: sessionItem)
                }
            ))
        }
    }

    /// 지각/결석 사유 제출 버튼 탭 처리
    @MainActor
    func attendanceReasonBtnTapped(
        userId: UserID,
        sessionItem: SessionItem,
        reason: String
    ) async {
        let session = sessionItem.session
        let timeWindow = currentTimeWindow(for: session)
        guard timeWindow == .lateWindow || timeWindow == .expired else { return }

        sessionItem.updateState(.loading)
        
        do {
            let result = try await challengeAttendanceUseCase.submitLateReason(
                sessionId: session.sessionId, userId: userId, reason: reason)
            sessionItem.updateState(.loaded(result))

        } catch let error as DomainError {
            sessionItem.updateState(.failed(.domain(error)))
        } catch {
            // 기타 에러 (네트워크 등)
            if let attendance = sessionItem.attendance {
                sessionItem.updateState(.loaded(attendance))
            }
            errorHandler.handle(error, context: .init(
                feature: "Activity",
                action: "attendanceReasonBtnTapped",
                retryAction: { [weak self] in
                    await self?.attendanceReasonBtnTapped(
                        userId: userId,
                        sessionItem: sessionItem,
                        reason: reason
                    )
                }
            ))
        }
    }
    
    func isAttendanceAvailable(for item: SessionItem) -> Bool {
        currentTimeWindow(for: item.session) == .onTime
        && challengeAttendanceUseCase.isInsideGeofence
        && challengeAttendanceUseCase.isLocationAuthorized
        && !item.isLoading
        && !item.hasSubmitted
    }
    
    func buttonStyle(for item: SessionItem) -> String {
        item.buttonTitle(
            isLocationAuthorized: challengeAttendanceUseCase.isLocationAuthorized,
            isInsideGeofence: challengeAttendanceUseCase.isInsideGeofence,
            timeWindow: challengeAttendanceUseCase.isWithinAttendanceTime(session: item.session)
        )
    }
    
    // MARK: - Helper Methods
    
    private func currentTimeWindow(for session: Session) -> AttendanceTimeWindow {
        challengeAttendanceUseCase.isWithinAttendanceTime(session: session)
    }
}
