//
//  OperatorAttendanceViewModel.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/5/26.
//

import Foundation

/// 운영진 출석 관리 ViewModel
///
/// 세션별 출석 현황 조회, 승인/반려 액션을 관리합니다.
@Observable
final class OperatorAttendanceViewModel {

    // MARK: - Property

    private var container: DIContainer
    private var errorHandler: ErrorHandler
    private var useCase: OperatorAttendanceUseCaseProtocol

    /// 세션 출석 현황 목록
    private(set) var sessionsState: Loadable<[OperatorSessionAttendance]> = .idle

    /// AlertPrompt 상태 (사유 확인, 승인/반려 확인)
    var alertPrompt: AlertPrompt?

    /// 위치 변경 시트 표시 여부
    var showLocationSheet: Bool = false

    /// 현재 선택된 세션 (위치 변경용)
    var selectedSession: Session?

    /// 현재 처리 중인 멤버 ID (해당 버튼만 ProgressView 표시)
    private(set) var processingMemberIds: Set<UUID> = []

    // MARK: - Init

    init(
        container: DIContainer,
        errorHandler: ErrorHandler,
        useCase: OperatorAttendanceUseCaseProtocol
    ) {
        self.container = container
        self.errorHandler = errorHandler
        self.useCase = useCase
    }

    // MARK: - Action

    /// 세션 목록에서 pending 출석 조회
    @MainActor
    func fetchSessions(from sessions: [Session]) async {
        sessionsState = .loading
        var updatedSessions: [OperatorSessionAttendance] = []

        for session in sessions {
            let scheduleIdString = session.id.value
            var pendingMembers: [OperatorPendingMember] = []

            if let scheduleId = Int(scheduleIdString) {
                do {
                    let records = try await useCase
                        .fetchPendingAttendances(
                            scheduleId: scheduleId
                        )
                    pendingMembers = records.map {
                        OperatorPendingMember(from: $0)
                    }
                } catch {
                    // API 실패 시 빈 목록으로 진행
                }
            }

            // TODO: 서버에서 출석 집계(total/attended/rate) 제공 시 해당 값으로 교체
            let sessionStatus = OperatorSessionStatus.from(
                startTime: session.info.startTime,
                endTime: session.info.endTime
            )
            let totalCount = sessionStatus == .beforeStart ? 0 : 40
            let attendedCount = max(0, totalCount - pendingMembers.count)
            let attendanceRate = totalCount > 0
                ? Double(attendedCount) / Double(totalCount)
                : 0

            updatedSessions.append(OperatorSessionAttendance(
                serverID: scheduleIdString,
                session: session,
                attendanceRate: attendanceRate,
                attendedCount: attendedCount,
                totalCount: totalCount,
                pendingMembers: pendingMembers
            ))
        }

        sessionsState = .loaded(updatedSessions)
    }

    /// 위치 변경 버튼 탭
    func locationButtonTapped(session: Session) {
        selectedSession = session
        showLocationSheet = true
    }

    /// 출석 사유 확인 버튼 탭
    func reasonButtonTapped(member: OperatorPendingMember) {
        guard let reason = member.reason else { return }

        alertPrompt = AlertPrompt(
            title: "출석 사유",
            message: reason,
            positiveBtnTitle: "확인",
            positiveBtnAction: { [weak self] in
                self?.alertPrompt = nil
            }
        )
    }

    /// 승인 버튼 탭
    func approveButtonTapped(member: OperatorPendingMember, sessionId: UUID) {
        alertPrompt = AlertPrompt(
            title: "출석 승인",
            message: "\(member.name)님의 출석을 승인하시겠습니까?",
            positiveBtnTitle: "승인",
            positiveBtnAction: { [weak self] in
                Task {
                    await self?.approveAttendance(memberId: member.id, sessionId: sessionId)
                }
            },
            negativeBtnTitle: "취소",
            negativeBtnAction: { [weak self] in
                self?.alertPrompt = nil
            }
        )
    }

    /// 반려 버튼 탭
    func rejectButtonTapped(member: OperatorPendingMember, sessionId: UUID) {
        alertPrompt = AlertPrompt(
            title: "출석 반려",
            message: "\(member.name)님의 출석을 반려하시겠습니까?",
            positiveBtnTitle: "반려",
            positiveBtnAction: { [weak self] in
                Task {
                    await self?.rejectAttendance(memberId: member.id, sessionId: sessionId)
                }
            },
            negativeBtnTitle: "취소",
            negativeBtnAction: { [weak self] in
                self?.alertPrompt = nil
            },
            isPositiveBtnDestructive: true
        )
    }

    /// 전체 승인 버튼 탭
    func approveAllButtonTapped(sessionId: UUID) {
        alertPrompt = AlertPrompt(
            title: "전체 승인",
            message: "모든 승인 대기 출석을 승인하시겠습니까?",
            positiveBtnTitle: "전체 승인",
            positiveBtnAction: { [weak self] in
                Task {
                    await self?.approveAllAttendances(sessionId: sessionId)
                }
            },
            negativeBtnTitle: "취소",
            negativeBtnAction: { [weak self] in
                self?.alertPrompt = nil
            }
        )
    }

    /// 전체 거절 버튼 탭
    func rejectAllButtonTapped(sessionId: UUID) {
        alertPrompt = AlertPrompt(
            title: "전체 거절",
            message: "모든 승인 대기 출석을 거절하시겠습니까?",
            positiveBtnTitle: "전체 거절",
            positiveBtnAction: { [weak self] in
                Task {
                    await self?.rejectAllAttendances(sessionId: sessionId)
                }
            },
            negativeBtnTitle: "취소",
            negativeBtnAction: { [weak self] in
                self?.alertPrompt = nil
            },
            isPositiveBtnDestructive: true
        )
    }

    /// 선택 승인 버튼 탭
    func approveSelectedButtonTapped(members: [OperatorPendingMember], sessionId: UUID) {
        guard !members.isEmpty else { return }

        alertPrompt = AlertPrompt(
            title: "선택 승인",
            message: "\(members.count)명의 출석을 승인하시겠습니까?",
            positiveBtnTitle: "승인",
            positiveBtnAction: { [weak self] in
                Task {
                    await self?.approveSelectedAttendances(members: members, sessionId: sessionId)
                }
            },
            negativeBtnTitle: "취소",
            negativeBtnAction: { [weak self] in
                self?.alertPrompt = nil
            }
        )
    }

    /// 선택 거절 버튼 탭
    func rejectSelectedButtonTapped(members: [OperatorPendingMember], sessionId: UUID) {
        guard !members.isEmpty else { return }

        alertPrompt = AlertPrompt(
            title: "선택 거절",
            message: "\(members.count)명의 출석을 거절하시겠습니까?",
            positiveBtnTitle: "거절",
            positiveBtnAction: { [weak self] in
                Task {
                    await self?.rejectSelectedAttendances(members: members, sessionId: sessionId)
                }
            },
            negativeBtnTitle: "취소",
            negativeBtnAction: { [weak self] in
                self?.alertPrompt = nil
            },
            isPositiveBtnDestructive: true
        )
    }

    /// 확인 없이 즉시 출석 승인 (사유 확인 AlertPrompt에서 호출)
    func approveDirectly(member: OperatorPendingMember, sessionId: UUID) {
        Task {
            await approveAttendance(memberId: member.id, sessionId: sessionId)
        }
    }

    /// 확인 없이 즉시 출석 반려 (사유 확인 AlertPrompt에서 호출)
    func rejectDirectly(member: OperatorPendingMember, sessionId: UUID) {
        Task {
            await rejectAttendance(memberId: member.id, sessionId: sessionId)
        }
    }

    // MARK: - Private Action

    @MainActor
    private func approveAttendance(
        memberId: UUID,
        sessionId: UUID
    ) async {
        alertPrompt = nil
        guard case .loaded(let sessions) = sessionsState,
              let session = sessions.first(where: {
                  $0.id == sessionId
              }),
              let member = session.pendingMembers.first(where: {
                  $0.id == memberId
              }),
              let recordId = Int(member.serverID ?? "")
        else { return }

        processingMemberIds.insert(memberId)
        defer { processingMemberIds.remove(memberId) }

        do {
            try await useCase.approveAttendance(
                recordId: recordId
            )
            updateSessionByRemovingMember(
                memberId: memberId,
                sessionId: sessionId,
                isApproval: true
            )
        } catch {
            errorHandler.handle(error, context: .init(
                feature: "Activity",
                action: "approveAttendance"
            ))
        }
    }

    @MainActor
    private func rejectAttendance(
        memberId: UUID,
        sessionId: UUID
    ) async {
        alertPrompt = nil
        guard case .loaded(let sessions) = sessionsState,
              let session = sessions.first(where: {
                  $0.id == sessionId
              }),
              let member = session.pendingMembers.first(where: {
                  $0.id == memberId
              }),
              let recordId = Int(member.serverID ?? "")
        else { return }

        processingMemberIds.insert(memberId)
        defer { processingMemberIds.remove(memberId) }

        do {
            try await useCase.rejectAttendance(
                recordId: recordId
            )
            updateSessionByRemovingMember(
                memberId: memberId,
                sessionId: sessionId,
                isApproval: false
            )
        } catch {
            errorHandler.handle(error, context: .init(
                feature: "Activity",
                action: "rejectAttendance"
            ))
        }
    }

    @MainActor
    private func approveAllAttendances(sessionId: UUID) async {
        alertPrompt = nil
        guard case .loaded(let sessions) = sessionsState,
              let session = sessions.first(where: {
                  $0.id == sessionId
              })
        else { return }

        for member in session.pendingMembers {
            guard let recordId = Int(member.serverID ?? "")
            else { continue }
            try? await useCase.approveAttendance(
                recordId: recordId
            )
        }
        updateSessionByRemovingAllMembers(
            sessionId: sessionId,
            isApproval: true
        )
    }

    @MainActor
    private func rejectAllAttendances(sessionId: UUID) async {
        alertPrompt = nil
        guard case .loaded(let sessions) = sessionsState,
              let session = sessions.first(where: {
                  $0.id == sessionId
              })
        else { return }

        for member in session.pendingMembers {
            guard let recordId = Int(member.serverID ?? "")
            else { continue }
            try? await useCase.rejectAttendance(
                recordId: recordId
            )
        }
        updateSessionByRemovingAllMembers(
            sessionId: sessionId,
            isApproval: false
        )
    }

    @MainActor
    private func approveSelectedAttendances(
        members: [OperatorPendingMember],
        sessionId: UUID
    ) async {
        alertPrompt = nil

        for member in members {
            guard let recordId = Int(member.serverID ?? "")
            else { continue }
            try? await useCase.approveAttendance(
                recordId: recordId
            )
        }
        updateSessionByRemovingSelectedMembers(
            memberIds: members.map(\.id),
            sessionId: sessionId,
            isApproval: true
        )
    }

    @MainActor
    private func rejectSelectedAttendances(
        members: [OperatorPendingMember],
        sessionId: UUID
    ) async {
        alertPrompt = nil

        for member in members {
            guard let recordId = Int(member.serverID ?? "")
            else { continue }
            try? await useCase.rejectAttendance(
                recordId: recordId
            )
        }
        updateSessionByRemovingSelectedMembers(
            memberIds: members.map(\.id),
            sessionId: sessionId,
            isApproval: false
        )
    }

    // MARK: - Helper

    private func updateSessionByRemovingMember(
        memberId: UUID,
        sessionId: UUID,
        isApproval: Bool
    ) {
        guard case .loaded(var sessions) = sessionsState else { return }

        if let index = sessions.firstIndex(where: { $0.id == sessionId }) {
            let updatedMembers = sessions[index].pendingMembers.filter { $0.id != memberId }
            sessions[index] = sessions[index].copyWith(
                attendedCount: isApproval
                    ? sessions[index].attendedCount + 1
                    : sessions[index].attendedCount,
                pendingMembers: updatedMembers
            )
            sessionsState = .loaded(sessions)
            notifySharedSessionChange(
                session: sessions[index],
                isApproval: isApproval
            )
        }
    }

    private func updateSessionByRemovingAllMembers(sessionId: UUID, isApproval: Bool) {
        guard case .loaded(var sessions) = sessionsState else { return }

        if let index = sessions.firstIndex(where: { $0.id == sessionId }) {
            let memberCount = sessions[index].pendingMembers.count
            sessions[index] = sessions[index].copyWith(
                attendedCount: isApproval
                    ? sessions[index].attendedCount + memberCount
                    : sessions[index].attendedCount,
                pendingMembers: []
            )
            sessionsState = .loaded(sessions)
            notifySharedSessionChange(
                session: sessions[index],
                isApproval: isApproval
            )
        }
    }

    private func updateSessionByRemovingSelectedMembers(
        memberIds: [UUID],
        sessionId: UUID,
        isApproval: Bool
    ) {
        guard case .loaded(var sessions) = sessionsState else { return }

        if let index = sessions.firstIndex(where: { $0.id == sessionId }) {
            let memberIdSet = Set(memberIds)
            let updatedMembers = sessions[index].pendingMembers.filter {
                !memberIdSet.contains($0.id)
            }
            sessions[index] = sessions[index].copyWith(
                attendedCount: isApproval
                    ? sessions[index].attendedCount + memberIds.count
                    : sessions[index].attendedCount,
                pendingMembers: updatedMembers
            )
            sessionsState = .loaded(sessions)
            notifySharedSessionChange(
                session: sessions[index],
                isApproval: isApproval
            )
        }
    }

    /// 공유 Session 객체 출석 상태 업데이트 + Notification 발송
    ///
    /// 운영진 승인/반려 후 챌린저 뷰의 @Observable Session이
    /// 자동 갱신되도록 직접 업데이트합니다.
    private func notifySharedSessionChange(
        session: OperatorSessionAttendance,
        isApproval: Bool
    ) {
        let sharedSession = session.session
        let newStatus: AttendanceStatus = isApproval ? .present : .absent

        if sharedSession.hasSubmitted,
           let existing = sharedSession.attendance
        {
            sharedSession.updateState(.loaded(Attendance(
                sessionId: existing.sessionId,
                userId: existing.userId,
                type: existing.type,
                status: newStatus,
                locationVerification: existing.locationVerification,
                reason: existing.reason
            )))
        }

        NotificationCenter.default.post(
            name: .attendanceStatusChanged,
            object: nil
        )
    }

}
