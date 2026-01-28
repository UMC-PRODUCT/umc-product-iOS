//
//  AppBundleSection.swift
//  AppProduct
//
//  Created by euijjang97 on 1/28/26.
//

import SwiftUI

/// MyPage에서 앱 정보(버전 등)를 표시하는 Section 컴포넌트
///
/// 앱 번들 정보를 읽어 현재 앱 버전을 사용자에게 보여줍니다.
struct InfoSection: View {
    // MARK: - Property

    /// 섹션의 타입 (헤더 타이틀로 사용됨)
    let sectionType: MyPageSectionType

    /// Bundle에서 읽어온 앱 버전 정보
    /// - Returns: CFBundleShortVersionString 값, 없으면 "Unknown"
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    // MARK: - Function

    init(sectionType: MyPageSectionType) {
        self.sectionType = sectionType
    }

    // MARK: - Body

    var body: some View {
        Section(content: {
            MyPageSectionRow(systemIcon: "info.circle", title: "버전", rightText: appVersion)
        }, header: {
            SectionHeaderView(title: sectionType.rawValue)
        })
    }
}
