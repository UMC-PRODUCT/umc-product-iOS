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
}
