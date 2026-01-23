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
        .tabViewBottomAccessory(isEnabled: router.destination.isEmpty, content: {
            UmcBottonAccessoryView(tabCase: $tabCase)
        })
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
            Text("11")
        case .community:
            Text("11")
        case .mypage:
            Text("11")
        }
    }
}

#Preview {
    UmcTab()
}
