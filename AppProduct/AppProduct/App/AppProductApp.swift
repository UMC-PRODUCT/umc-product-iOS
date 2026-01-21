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
//            UmcTab()
//                .environment(errorHandler)
//                .environment(\.di, container)
//                .modelContainer(for: NoticeHistoryData.self)
            VStack {
                ScheduleListCard(data: .init(title: "컨퍼런스", subTitle: "테스트"))
                ScheduleListCard(data: .init(title: "데모데이", subTitle: "테스트"))
            }
        }
    }
}
