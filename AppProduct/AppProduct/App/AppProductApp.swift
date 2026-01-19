//
//  AppProductApp.swift
//  AppProduct
//
//  Created by jaewon Lee on 12/30/25.
//

import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth

@main
struct AppProductApp: App {
    @State private var container: DIContainer = DIContainer.configured()
    @State var show: Bool = false
    
    var body: some Scene {
        WindowGroup {
            testView
            //!!!: - 사용 시 주석 풀기
                .environment(\.di, container)
        }
    }
    
    private var testView: some  View {
        NavigationStack {
            HomeView()
        }
    }
}
