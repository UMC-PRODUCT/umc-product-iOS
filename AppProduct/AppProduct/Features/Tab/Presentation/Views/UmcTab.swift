//
//  umcTab.swift
//  AppProduct
//
//  Created by euijjang97 on 1/19/26.
//

import SwiftUI

/// 메인 탭 네비게이션 뷰
///
/// Home, Notice, Activity, Community, MyPage 5개 탭을 제공하며
/// 탭별 독립 NavigationStack으로 상태를 보존합니다.
struct UmcTab: View {

    // MARK: - Property

    @State var tabCase: TabCase = .home
    @State var isShowMyPage: Bool = false
    @Environment(\.di) var di
    @Environment(ErrorHandler.self) var errorHandler
    @AppStorage(AppStorageKey.memberRole) private var memberRoleRaw: String = ""
    @State private var didApplyDebugLaunchRoute: Bool = false

    private var pathStore: PathStore {
        di.resolve(PathStore.self)
    }

    private var effectiveMemberRole: ManagementTeam {
        if let role = ManagementTeam(rawValue: memberRoleRaw) {
            return role
        }
        return di.resolve(UserSessionManager.self).currentRole
    }

    // MARK: - Body

    var body: some View {
        TabView(selection: $tabCase, content: {
            ForEach(TabCase.allCases, id: \.id) { tab in
                Tab(value: tab, role: tab.tabRoloe, content: {
                    tabView(tab)
                }, label: {
                    tabLabel(tab)
                })
            }
        })
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory(isEnabled: shouldShowAccessory()) {
            UmcBottonAccessoryView(tabCase: $tabCase)
        }
        .task {
            applyDebugLaunchRouteIfNeeded()
        }
    }

    // MARK: - Private Function

    private func tabLabel(_ tab: TabCase) -> some View {
        VStack(alignment: .center, spacing: DefaultSpacing.spacing8, content: {
            tab.icon
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)

            Text(tab.title)
                .appFont(.caption1, weight: .regular)
        })
        .tint(.blue)
    }

    /// 탭 케이스에 따른 루트 뷰를 반환합니다.
    @ViewBuilder
    private func tabView(_ tab: TabCase) -> some View {
        switch tab {
        case .home:
            HomeView(container: di)
        case .notice:
            NoticeView(container: di)
        case .activity:
            ActivityView()
        case .community:
            CommunityView()
        case .mypage:
            MyPageView()
        }
    }

    /// Bottom Accessory 표시 여부 결정
    ///
    /// Activity 탭에서는 Admin 권한이 있는 경우에만 Accessory를 표시합니다.
    private func shouldShowAccessory() -> Bool {
        // 챌린저는 공지 탭에서만 Bottom Accessory를 노출하지 않음
        if tabCase == .notice && effectiveMemberRole == .challenger {
            return false
        }

        // MyPage 탭에서는 항상 Accessory 숨김
        if tabCase == .mypage {
            return false
        }

        // 현재 탭의 NavigationStack에 화면이 쌓여있으면 Accessory 숨김
        let currentPath: [NavigationDestination] = {
            switch tabCase {
            case .home: return pathStore.homePath
            case .notice: return pathStore.noticePath
            case .activity: return pathStore.activityPath
            case .community: return pathStore.communityPath
            case .mypage: return pathStore.mypagePath
            }
        }()

        guard currentPath.isEmpty else { return false }

        // Activity 탭에서는 Admin 토글 가능한 경우에만 표시
        if tabCase == .activity {
            let userSession = di.resolve(UserSessionManager.self)
            return userSession.canToggleAdminMode
        }

        return true
    }

    /// DEBUG 스킴 런치 인자에 따라 초기 탭/경로를 세팅합니다.
    private func applyDebugLaunchRouteIfNeeded() {
        #if DEBUG
        guard !didApplyDebugLaunchRoute else { return }
        didApplyDebugLaunchRoute = true

        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("--open-notice-editor") else { return }

        tabCase = .notice
        let destination = NavigationDestination.notice(.editor(mode: .create))
        Task { @MainActor in
            pathStore.appendNoticePathIfNeeded(destination)
        }
        #endif
    }
}

#Preview {
    UmcTab()
}
