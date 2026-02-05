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

        // TODO: 실제 API 연동 시 구현
        // Mock 데이터로 임시 구현
        do {
            try await Task.sleep(for: .milliseconds(500))
            let mockData = createMockSessions()
            sessionsState = .loaded(mockData)
        } catch {
            sessionsState = .failed(.unknown(message: "데이터 로딩 실패"))
        }
    }

    /// 위치 변경 버튼 탭
    func locationButtonTapped(session: Session) {
        selectedSession = session
        showLocationSheet = true
    }

    /// 출석 사유 확인 버튼 탭
    func reasonButtonTapped(member: PendingMember) {
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
    func approveButtonTapped(member: PendingMember, sessionId: String) {
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
    func rejectButtonTapped(member: PendingMember, sessionId: String) {
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
    func approveAllButtonTapped(sessionId: String) {
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

    // MARK: - Private Action

    @MainActor
    private func approveAttendance(memberId: String, sessionId: String) async {
        alertPrompt = nil

        // TODO: 실제 API 연동
        // try await useCase.approveAttendance(attendanceId: AttendanceID(value: memberId))

        // Mock: 해당 멤버 제거
        updateSessionByRemovingMember(memberId: memberId, sessionId: sessionId)
    }

    @MainActor
    private func rejectAttendance(memberId: String, sessionId: String) async {
        alertPrompt = nil

        // TODO: 실제 API 연동
        // try await useCase.rejectAttendance(attendanceId: AttendanceID(value: memberId), reason: "")

        // Mock: 해당 멤버 제거
        updateSessionByRemovingMember(memberId: memberId, sessionId: sessionId)
    }

    @MainActor
    private func approveAllAttendances(sessionId: String) async {
        alertPrompt = nil

        // TODO: 실제 API 연동
        // try await useCase.approveAllAttendances(sessionId: SessionID(value: sessionId))

        // Mock: 모든 멤버 제거
        updateSessionByRemovingAllMembers(sessionId: sessionId)
    }

    // MARK: - Helper

    private func updateSessionByRemovingMember(memberId: String, sessionId: String) {
        guard case .loaded(var sessions) = sessionsState else { return }

        if let index = sessions.firstIndex(where: { $0.id == sessionId }) {
            let updatedMembers = sessions[index].pendingMembers.filter { $0.id != memberId }
            let session = sessions[index]
            sessions[index] = OperatorSessionAttendance(
                id: session.id,
                session: session.session,
                attendanceRate: session.attendanceRate,
                attendedCount: session.attendedCount + 1,
                totalCount: session.totalCount,
                pendingMembers: updatedMembers
            )
            sessionsState = .loaded(sessions)
        }
    }

    private func updateSessionByRemovingAllMembers(sessionId: String) {
        guard case .loaded(var sessions) = sessionsState else { return }

        if let index = sessions.firstIndex(where: { $0.id == sessionId }) {
            let session = sessions[index]
            let approvedCount = session.pendingMembers.count
            sessions[index] = OperatorSessionAttendance(
                id: session.id,
                session: session.session,
                attendanceRate: session.attendanceRate,
                attendedCount: session.attendedCount + approvedCount,
                totalCount: session.totalCount,
                pendingMembers: []
            )
            sessionsState = .loaded(sessions)
        }
    }

    // MARK: - Mock Data

    private func createMockSessions() -> [OperatorSessionAttendance] {
        // AttendancePreviewData.sessions 활용
        let sessions = AttendancePreviewData.sessions

        return [
            OperatorSessionAttendance(
                id: "session_1",
                session: sessions[1],
                attendanceRate: 0.85,
                attendedCount: 34,
                totalCount: 40,
                pendingMembers: [
                    PendingMember(
                        id: "member_1",
                        name: "홍길동",
                        nickname: "닉네임",
                        university: "중앙대학교",
                        requestTime: Date.now.addingTimeInterval(-300),
                        reason: "지각 사유입니다. 버스가 늦게 와서 조금 늦었습니다."
                    ),
                    PendingMember(
                        id: "member_2",
                        name: "김철수",
                        nickname: nil,
                        university: "한성대학교",
                        requestTime: Date.now.addingTimeInterval(-600),
                        reason: nil
                    ),
                    PendingMember(
                        id: "member_3",
                        name: "이영희",
                        nickname: "영희짱",
                        university: "서울대학교",
                        requestTime: Date.now.addingTimeInterval(-900),
                        reason: "교통 체증으로 인한 지각"
                    )
                ]
            ),
            OperatorSessionAttendance(
                id: "session_2",
                session: sessions[0],
                attendanceRate: 1.0,
                attendedCount: 40,
                totalCount: 40,
                pendingMembers: []  // 모두 승인 완료
            )
        ]
    }
}
