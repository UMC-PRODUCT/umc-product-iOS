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
/// 상단 Menu(principal)로 섹션을 선택하고, Bottom Accessory로 모드를 전환합니다.
struct ActivityView: View {
    @Environment(\.di) private var di
    @State private var selectedSection: ActivitySection?
    @State private var errorHandler = ErrorHandler()

    // MARK: - Computed Property

    private var userSession: UserSessionManager {
        di.resolve(UserSessionManager.self)
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
    }

    // MARK: - View Component

    /// Tide 앱 스타일 섹션 선택 Menu (principal 배치)
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
            // TODO: 실제 사용자 ID와 세션 데이터는 ViewModel에서 제공해야 함
            AttendanceSessionView(
                container: di,
                errorHandler: errorHandler,
                sessions: AttendancePreviewData.sessions,
                userId: AttendancePreviewData.userId
            )
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
}

#Preview("Challenger Mode") {
    NavigationStack {
        ActivityView()
    }
    .environment(\.di, DIContainer.configured())
}
