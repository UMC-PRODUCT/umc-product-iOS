//
//  HelpSection.swift
//  AppProduct
//
//  Created by euijjang97 on 1/28/26.
//

import SwiftUI

/// MyPage에서 지원센터(고객 지원, 문의 등)로 이동하는 Section 컴포넌트
struct HelpSection: View {
    // MARK: - Property

    @Environment(\.di) var di
    /// 섹션의 타입 (헤더 타이틀로 사용됨)
    let sectionType: MyPageSectionType

    /// DI Container에서 주입받은 NavigationRouter
    private var router: NavigationRouter {
        di.resolve(NavigationRouter.self)
    }

    private enum Constants {
        static let icon: String = "bubble.left.and.bubble.right"
        static let chevron: String = "chevron.right"
    }

    // MARK: - Function

    init(sectionType: MyPageSectionType) {
        self.sectionType = sectionType
    }

    // MARK: - Body

    var body: some View {
        Section(content: {
            row
        }, header: {
            SectionHeaderView(title: "지원센터")
        })
    }

    /// 지원센터로 이동하는 Row 버튼
    private var row: some View {
        Button(action: {
            // TODO: 지원센터 화면으로 네비게이션
            print("hello")
        }, label: {
            MyPageSectionRow(systemIcon: "bubble.left.and.bubble.right", title: sectionType.rawValue, rightImage: Constants.chevron)
        })
    }
}
