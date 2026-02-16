//
//  PathStore.swift
//  AppProduct
//
//  Created by euijjang97 on 2/4/26.
//

import Foundation

/// 각 탭별 네비게이션 경로를 중앙에서 관리하는 Store
@Observable
final class PathStore {
    var homePath: [NavigationDestination] = []
    var noticePath: [NavigationDestination] = []
    var activityPath: [NavigationDestination] = []
    var communityPath: [NavigationDestination] = []
    var mypagePath: [NavigationDestination] = []
    private var isUpdatingNoticePath: Bool = false

    /// 공지 탭 path를 같은 프레임에 중복 갱신하지 않도록 보호합니다.
    @MainActor
    func appendNoticePathIfNeeded(_ destination: NavigationDestination) {
        guard noticePath.last != destination else { return }
        guard !isUpdatingNoticePath else { return }

        isUpdatingNoticePath = true
        noticePath.append(destination)

        Task { @MainActor in
            await Task.yield()
            isUpdatingNoticePath = false
        }
    }
}
