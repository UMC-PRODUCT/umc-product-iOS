//
//  TabDebugLaunchScheme.swift
//  AppProduct
//
//  Created by euijjang97 on 2/17/26.
//

import Foundation

#if DEBUG
/// 디버그 스킴 런치 인자 기반 탭 진입 경로
enum TabDebugLaunchRoute {
    case openNoticeTab

    /// 런치 인자에서 최초 매칭되는 디버그 진입 경로를 반환합니다.
    static func fromLaunchArguments(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> TabDebugLaunchRoute? {
        if arguments.contains("--open-notice-tab") {
            return .openNoticeTab
        }
        return nil
    }
}
#endif
