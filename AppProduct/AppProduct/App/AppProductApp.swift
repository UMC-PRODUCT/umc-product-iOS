//
//  AppProductApp.swift
//  AppProduct
//
//  Created by jaewon Lee on 12/30/25.
//

import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth
import SwiftData

@main
struct AppProductApp: App {
    @State private var container: DIContainer = DIContainer.configured()
    @State private var errorHandler: ErrorHandler = .init()
    @State var show: Bool = false

    var body: some Scene {
        WindowGroup {
            UmcTab()
                .environment(errorHandler)
                .environment(\.di, container)
                .modelContainer(for: NoticeHistoryData.self)
        }
    }
}
