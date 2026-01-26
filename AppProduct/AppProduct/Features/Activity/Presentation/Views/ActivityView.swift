//
//  ActivityView.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/23/26.
//

import SwiftUI

/// Activity Feature 메인 화면
///
/// Challenger/Admin 모드에 따라 다른 섹션을 표시합니다.
/// 상단 Menu(trailing)로 섹션을 선택하고, Bottom Accessory로 모드를 전환합니다.
struct ActivityView: View {
    @Environment(\.di) private var di
    @State private var selectedSection: ActivitySection?
    @State private var errorHandler = ErrorHandler()
    @State private var viewModel: ActivityViewModel?

    // MARK: - Computed Property

    private var userSession: UserSessionManager {
        di.resolve(UserSessionManager.self)
    }

    /// Provider를 통해 UseCase 접근
    private var activityProvider: ActivityUseCaseProviding {
        di.resolve(ActivityUseCaseProviding.self)
    }

    /// 현재 모드에서 사용 가능한 섹션 목록
    private var availableSections: [ActivitySection] {
        ActivitySection.sections(for: userSession.currentActivityMode)
    }

    /// 현재 선택된 섹션 (선택 없으면 기본 섹션)
    private var currentSection: ActivitySection {
        selectedSection ?? ActivitySection.defaultSection(for: userSession.currentActivityMode)
    }

    // MARK: - Body

    var body: some View {
        sectionContent(
            for: currentSection,
            mode: userSession.currentActivityMode
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                sectionMenu
            }
        }
        .navigation(naviTitle: .activityManagementType, displayMode: .inline)
        .onChange(of: userSession.currentActivityMode) { _, _ in
            // 모드 전환 시 기본 섹션으로 리셋
            selectedSection = nil
        }
        .task {
            // ViewModel 초기화 및 데이터 로드
            if viewModel == nil {
                viewModel = ActivityViewModel(
                    fetchSessionsUseCase: activityProvider.fetchSessionsUseCase,
                    fetchUserIdUseCase: activityProvider.fetchUserIdUseCase,
                    classifyScheduleUseCase: activityProvider.classifyScheduleUseCase
                )
            }
            await viewModel?.loadInitialData()
        }
    }

    // MARK: - View Component

    /// 섹션 선택 Menu
    private var sectionMenu: some View {
        Menu {
            ForEach(availableSections) { section in
                Button {
                    withAnimation(.snappy) {
                        selectedSection = section
                    }
                } label: {
                    Label(section.rawValue, systemImage: section.icon)
                }
            }
        } label: {
            HStack(spacing: DefaultSpacing.spacing4) {
                Text(currentSection.rawValue)
                    .appFont(.body)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
        }
    }

    /// 섹션에 해당하는 뷰 반환
    @ViewBuilder
    private func sectionContent(
        for section: ActivitySection,
        mode: ActivityMode
    ) -> some View {
        switch (mode, section) {
        case (.challenger, .attendanceCheck):
            attendanceContent
        case (.challenger, .studyActivity):
            ChallengerStudyView()
        case (.challenger, .members):
            MemberListView()
        case (.admin, .attendanceManage):
            OperatorAttendanceSectionView(
                container: di,
                errorHandler: errorHandler
            )
        case (.admin, .studyManage):
            StudyManagementView()
        case (.admin, .memberManage):
            MemberManagementView()
        default:
            EmptyView()
        }
    }

    /// 출석 확인 섹션 (ViewModel 상태에 따라 표시)
    @ViewBuilder
    private var attendanceContent: some View {
        if let vm = viewModel {
            switch vm.sessionsState {
            case .idle, .loading:
                ProgressView("세션 로딩 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded(let sessions):
                AttendanceSessionView(
                    container: di,
                    errorHandler: errorHandler,
                    sessions: sessions,
                    userId: vm.userId ?? UserID(value: ""),
                    categoryFor: vm.category(for:)
                )
            case .failed(let error):
                ContentUnavailableView {
                    Label("로딩 실패", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                } actions: {
                    Button("다시 시도") {
                        Task { await vm.fetchSessions() }
                    }
                }
            }
        } else {
            ProgressView()
        }
    }
}

#Preview("Challenger Mode") {
    NavigationStack {
        ActivityView()
    }
    .environment(\.di, DIContainer.configured())
}
