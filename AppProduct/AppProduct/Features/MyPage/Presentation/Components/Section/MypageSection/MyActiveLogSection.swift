//
//  MyActiveLogSection.swift
//  AppProduct
//
//  Created by euijjang97 on 1/28/26.
//

import SwiftUI

/// MyPage에서 사용자의 활동 내역(작성 글, 댓글, 스크랩 등)을 표시하는 Section 컴포넌트
///
/// - Note: 현재는 빈 Section으로, 향후 활동 내역 기능이 구현될 예정입니다.
struct MyActiveLogSection: View {
    // MARK: - Property

    /// 섹션의 타입 (헤더 타이틀로 사용됨)
    let sectionType: MyPageSectionType
    @Environment(\.di) var di

    /// DI Container에서 주입받은 NavigationRouter
    private var router: NavigationRouter {
        di.resolve(NavigationRouter.self)
    }

    // MARK: - Function

    init(sectionType: MyPageSectionType) {
        self.sectionType = sectionType
    }

    // MARK: - Body

    var body: some View {
        Section(content: {
            sectionRow
        }, header: {
            SectionHeaderView(title: sectionType.rawValue)
        })
    }
    
    @ViewBuilder
    private var sectionRow: some View {
        ForEach(MyActiveLogsType.allCases, id: \.hashValue) { log in
            sectionContent(log)
        }
    }
    
    private func sectionContent(_ log: MyActiveLogsType) -> some View {
        Button(action: {
            sectionAction(log)
        }, label: {
            MyPageSectionRow(systemIcon: log.icon, title: log.rawValue, rightImage: "chevron.right", iconBackgroundColor: log.backgroundColor)
        })
    }
    
    private func sectionAction(_ log: MyActiveLogsType) {
        switch log {
        case .myWritePost:
            print("내 가 쓴글")
        case .myWriteComment:
            print("댓글 단 글")
        case .myScrapPost:
            print("스크랩")
        }
    }
}
