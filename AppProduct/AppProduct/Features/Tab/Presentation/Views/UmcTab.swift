//
//  umcTab.swift
//  AppProduct
//
//  Created by euijjang97 on 1/19/26.
//

import SwiftUI

struct UmcTab: View {
    @State var tabCase: TabCase = .home
    @State var isShowMyPage: Bool = false
    @Environment(\.di) var di
    @Environment(ErrorHandler.self) var errorHandler
    
    var body: some View {
        let router = di.resolve(NavigationRouter.self)

        TabView(selection: $tabCase, content: {
            ForEach(TabCase.allCases, id: \.id) { tab in
                Tab(value: tab, role: tab.tabRoloe, content: {
                    NavigationStack(path: Binding(
                        get: { router.destination },
                        set: { router.destination = $0 }
                    ), root: {
                        tabView(tab)
                            .navigationDestination(for: NavigationDestination.self) { destination in
                                NavigationRoutingView(destination: destination)
                            }
                    })
                }, label: {
                    tabLabel(tab)
                })
            }
        })
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory(isEnabled: shouldShowAccessory(router: router)) {
            UmcBottonAccessoryView(tabCase: $tabCase)
        }
    }

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

    @ViewBuilder
    private func tabView(_ tab: TabCase) -> some View {
        switch tab {
        case .home:
            HomeView()
        case .notice:
            NoticeView()
        case .activity:
            ActivityView()
        case .community:
            CommunityView()
        case .mypage:
            Text("11")
        }
    }

    /// Bottom Accessory 표시 여부 결정
    ///
    /// Activity 탭에서는 Admin 권한이 있는 경우에만 Accessory를 표시합니다.
    private func shouldShowAccessory(router: NavigationRouter) -> Bool {
        // NavigationStack에 화면이 쌓여있으면 Accessory 숨김
        guard router.destination.isEmpty else { return false }

        // Activity 탭에서는 Admin 토글 가능한 경우에만 표시
        if tabCase == .activity {
            let userSession = di.resolve(UserSessionManager.self)
            return userSession.canToggleAdminMode
        }

        return true
    }
}

#Preview {
    UmcTab()
}
