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
        TabView(selection: $tabCase, content: {
            ForEach(TabCase.allCases, id: \.id) { tab in
                Tab(value: tab, role: tab.tabRoloe, content: {
                    NavigationStack {
                        tabView(tab)
                    }
                }, label: {
                    tabLabel(tab)
                })
            }
        })
        .tabBarMinimizeBehavior(.onScrollDown)
//        .tabBarMinimizeBehavior(.onScrollUp)
        .tabViewBottomAccessory(content: {
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
            Text("11")
        case .activity:
            Text("11")
        case .community:
            Text("11")
        case .mypage:
            Text("11")
        }
    }
}
