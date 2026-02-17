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

    // MARK: - Property

    /// 홈 탭 네비게이션 경로
    var homePath: [NavigationDestination] = []
    /// 공지 탭 네비게이션 경로
    var noticePath: [NavigationDestination] = []
    /// 활동 탭 네비게이션 경로
    var activityPath: [NavigationDestination] = []
    /// 커뮤니티 탭 네비게이션 경로
    var communityPath: [NavigationDestination] = []
    /// 마이페이지 탭 네비게이션 경로
    var mypagePath: [NavigationDestination] = []
    /// 공지 path 중복 append 보호 플래그
    private var isUpdatingNoticePath: Bool = false

    // MARK: - Function

    /// 공지 탭 path를 같은 프레임에 중복 갱신하지 않도록 보호합니다.
    /// - Parameter destination: 공지 탭에 push할 목적지
    @MainActor
    func appendNoticePathIfNeeded(_ destination: NavigationDestination) {
        guard noticePath.last != destination else { return }
        guard !isUpdatingNoticePath else { return }

        isUpdatingNoticePath = true
        noticePath.append(destination)

        // 현재 RunLoop 사이클이 끝난 뒤 플래그를 해제하여 같은 프레임 내 중복 append 방지
        Task { @MainActor in
            await Task.yield()
            isUpdatingNoticePath = false
        }
    }
}
