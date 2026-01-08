//
//  AppProductApp.swift
//  AppProduct
//
//  Created by jaewon Lee on 12/30/25.
//

import SwiftUI

@main
struct AppProductApp: App {
    @State private var container: DIContainer = DIContainer.configured()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
            //!!!: - 사용 시 주석 풀기
                .environment(\.di, container)
        }
    }
}
