//
//  RemoteNoticeScreenKey.swift
//  MaintenancePresentation
//
//  Created by euijjang97 on 9/17/26.
//

import MaintenanceDomain
import SwiftUI

/// 화면 트리 안쪽에서 "지금 이 화면"을 앱 루트의 안내 호스트까지 올려 보내는 키.
///
/// 흐름 상태·선택 탭은 각자 다른 뷰가 들고 있어 루트에서 직접 읽을 수 없다. 형제 뷰가 동시에
/// 값을 올리면 마지막 값을 쓰고 바깥에서 붙인 값이 안쪽 값을 덮으므로, 한 경로에 한 번만 붙인다.
public struct RemoteNoticeScreenKey: PreferenceKey {
    public static let defaultValue: RemoteNoticeScreen = .bootstrap

    public static func reduce(
        value: inout RemoteNoticeScreen,
        nextValue: () -> RemoteNoticeScreen
    ) {
        value = nextValue()
    }
}

public extension View {
    /// 이 뷰가 원격 안내의 대상 화면 `screen`임을 앱 루트에 알린다.
    func remoteNoticeScreen(_ screen: RemoteNoticeScreen) -> some View {
        preference(key: RemoteNoticeScreenKey.self, value: screen)
    }
}
