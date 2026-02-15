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

    private var pathStore: PathStore {
        di.resolve(PathStore.self)
    }

    // MARK: - Init
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

    /// 활동 로그 타입에 해당하는 Row를 생성합니다.
    private func sectionContent(_ log: MyActiveLogsType) -> some View {
        Button(action: {
            sectionAction(log)
        }, label: {
            MyPageSectionRow(systemIcon: log.icon, title: log.rawValue, rightImage: "chevron.right", iconBackgroundColor: log.backgroundColor)
        })
    }

    /// 활동 로그 Row 탭 시 해당 게시글 목록 화면으로 이동합니다.
    private func sectionAction(_ log: MyActiveLogsType) {
        pathStore.mypagePath.append(
            .myPage(.myActivePosts(type: log))
        )
    }
}
