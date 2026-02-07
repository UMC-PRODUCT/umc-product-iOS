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

    /// 세션 목록 조회
    @MainActor
    func fetchSessions() async {
        sessionsState = .loading

        // TODO: 실제 API 연동 시 구현 - [25.02.05] 이재원
        // Mock 데이터로 임시 구현
        #if DEBUG
        do {
            try await Task.sleep(for: .milliseconds(500))
            let mockData = OperatorAttendancePreviewData.createMockSessions()
            sessionsState = .loaded(mockData)
        } catch is CancellationError {
            // Task 취소 시 idle로 복구하여 재시도 가능하게 함
            sessionsState = .idle
            return
        } catch {
            sessionsState = .failed(.unknown(message: "데이터 로딩 실패"))
        }
        #endif
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

    // MARK: - Private Action

    @MainActor
    private func approveAttendance(memberId: UUID, sessionId: UUID) async {
        alertPrompt = nil

        // TODO: 실제 API 연동 - [25.02.05] 이재원
        // try await useCase.approveAttendance(attendanceId: AttendanceID(value: memberId))

        // Mock: 해당 멤버 제거
        updateSessionByRemovingMember(memberId: memberId, sessionId: sessionId)
    }

    @MainActor
    private func rejectAttendance(memberId: UUID, sessionId: UUID) async {
        alertPrompt = nil

        // TODO: 실제 API 연동 - [25.02.05] 이재원
        // try await useCase.rejectAttendance(attendanceId: AttendanceID(value: memberId), reason: "")

        // Mock: 해당 멤버 제거
        updateSessionByRemovingMember(memberId: memberId, sessionId: sessionId)
    }

    @MainActor
    private func approveAllAttendances(sessionId: UUID) async {
        alertPrompt = nil

        // TODO: 실제 API 연동 - [25.02.05] 이재원
        // try await useCase.approveAllAttendances(sessionId: SessionID(value: sessionId))

        // Mock: 모든 멤버 제거 (출석 처리)
        updateSessionByRemovingAllMembers(sessionId: sessionId, isApproval: true)
    }

    @MainActor
    private func rejectAllAttendances(sessionId: UUID) async {
        alertPrompt = nil

        // TODO: 실제 API 연동 - [25.02.05] 이재원
        // try await useCase.rejectAllAttendances(sessionId: SessionID(value: sessionId))

        // Mock: 모든 멤버 제거 (거절 처리 - 출석 수 증가 없음)
        updateSessionByRemovingAllMembers(sessionId: sessionId, isApproval: false)
    }

    @MainActor
    private func approveSelectedAttendances(
        members: [OperatorPendingMember],
        sessionId: UUID
    ) async {
        alertPrompt = nil

        // TODO: 실제 API 연동 - [25.02.07] 이재원
        // let memberIds = members.map { AttendanceID(value: $0.id) }
        // try await useCase.approveSelectedAttendances(attendanceIds: memberIds)

        // Mock: 선택된 멤버들 제거 (출석 처리)
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

        // TODO: 실제 API 연동 - [25.02.07] 이재원
        // let memberIds = members.map { AttendanceID(value: $0.id) }
        // try await useCase.rejectSelectedAttendances(attendanceIds: memberIds)

        // Mock: 선택된 멤버들 제거 (거절 처리 - 출석 수 증가 없음)
        updateSessionByRemovingSelectedMembers(
            memberIds: members.map(\.id),
            sessionId: sessionId,
            isApproval: false
        )
    }

    // MARK: - Helper

    private func updateSessionByRemovingMember(memberId: UUID, sessionId: UUID) {
        guard case .loaded(var sessions) = sessionsState else { return }

        if let index = sessions.firstIndex(where: { $0.id == sessionId }) {
            let updatedMembers = sessions[index].pendingMembers.filter { $0.id != memberId }
            sessions[index] = sessions[index].copyWith(
                attendedCount: sessions[index].attendedCount + 1,
                pendingMembers: updatedMembers
            )
            sessionsState = .loaded(sessions)
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
        }
    }

}
