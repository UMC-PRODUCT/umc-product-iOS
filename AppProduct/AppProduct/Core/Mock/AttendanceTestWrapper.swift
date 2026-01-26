//
//  AttendanceTestWrapper.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/23/26.
//

import SwiftUI

#if DEBUG
/// 시뮬레이터 테스트용 Wrapper View
///
/// 출석 상태 승인/거절 버튼을 제공하여 상태 전환을 테스트할 수 있습니다.
struct AttendanceTestWrapper: View {
    @State private var sessions: [Session] = AttendancePreviewData.testSessions
    @State private var showAdminPanel: Bool = false

    private let container = AttendancePreviewData.container
    private let errorHandler = AttendancePreviewData.errorHandler
    private let userId = AttendancePreviewData.userId

    var body: some View {
        ZStack(alignment: .bottom) {
//            Color.grey100.ignoresSafeArea()

            AttendanceSessionView(
                container: container,
                errorHandler: errorHandler,
                sessions: sessions,
                userId: userId
            )

            adminPanelButton
        }
        .sheet(isPresented: $showAdminPanel) {
            adminPanel
        }
    }

    // MARK: - Admin Panel Button

    private var adminPanelButton: some View {
        Button {
            showAdminPanel = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "person.badge.shield.checkmark")
                Text("관리자 패널")
            }
            .appFont(.caption1Emphasis, color: .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.indigo, in: Capsule())
        }
        .padding(.bottom, 16)
    }

    // MARK: - Admin Panel

    private var adminPanel: some View {
        NavigationStack {
            List {
                Section("승인 대기 중인 세션") {
                    let pendingSessions = sessions.filter {
                        $0.attendanceStatus == .pendingApproval
                    }

                    if pendingSessions.isEmpty {
                        Text("승인 대기 중인 세션이 없습니다")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(pendingSessions) { session in
                            sessionRow(session)
                        }
                    }
                }

                Section("출석 전 세션") {
                    let beforeSessions = sessions.filter {
                        $0.attendanceStatus == .beforeAttendance
                    }

                    if beforeSessions.isEmpty {
                        Text("출석 전 세션이 없습니다")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(beforeSessions) { session in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.info.title)
                                    .appFont(.body, color: .grey900)
                                Text("\(session.info.week)주차")
                                    .appFont(.caption1, color: .grey600)
                            }
                        }
                    }
                }

                Section("처리 완료 세션") {
                    let completedSessions = sessions.filter {
                        $0.attendanceStatus == .present ||
                        $0.attendanceStatus == .late ||
                        $0.attendanceStatus == .absent
                    }

                    ForEach(completedSessions) { session in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.info.title)
                                    .appFont(.body, color: .grey900)
                                Text("\(session.info.week)주차")
                                    .appFont(.caption1, color: .grey600)
                            }

                            Spacer()

                            Text(session.attendanceStatus.displayText)
                                .appFont(.caption1Emphasis, color: session.attendanceStatus.fontColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    session.attendanceStatus.backgroundColor,
                                    in: Capsule()
                                )
                        }
                    }
                }

                Section {
                    Button("모든 세션 초기화") {
                        resetAllSessions()
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("관리자 패널")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        showAdminPanel = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Session Row

    private func sessionRow(_ session: Session) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.info.title)
                        .appFont(.body, color: .grey900)
                    Text("\(session.info.week)주차")
                        .appFont(.caption1, color: .grey600)
                }

                Spacer()

                Text("승인 대기")
                    .appFont(.caption1Emphasis, color: .yellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.yellow.opacity(0.2), in: Capsule())
            }

            HStack(spacing: 12) {
                Button {
                    approveSession(session, status: .present)
                } label: {
                    Label("출석", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button {
                    approveSession(session, status: .late)
                } label: {
                    Label("지각", systemImage: "clock.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                Button {
                    approveSession(session, status: .absent)
                } label: {
                    Label("결석", systemImage: "xmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .font(.caption)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private func approveSession(_ session: Session, status: AttendanceStatus) {
        let newAttendance = Attendance(
            sessionId: session.info.sessionId,
            userId: userId,
            type: .gps,
            status: status,
            locationVerification: nil,
            reason: nil
        )
        session.updateState(.loaded(newAttendance))

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func resetAllSessions() {
        sessions = AttendancePreviewData.testSessions

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
}

#Preview {
    AttendanceTestWrapper()
}
#endif
