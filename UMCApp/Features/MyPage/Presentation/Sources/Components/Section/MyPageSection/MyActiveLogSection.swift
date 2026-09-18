//
//  MyActiveLogSection.swift
//  MyPagePresentation
//
//  Created by euijjang97 on 8/10/26.
//

import CoreDesignSystem
import CoreUIComponents
import SwiftUI

/// v3 루트의 「커뮤니티 활동」 섹션 — 내가 쓴 글 / 댓글 단 글 / 스크랩으로 이동한다.
public struct MyActiveLogSection: View {

    // MARK: - Property

    private let sectionType: MyPageSectionType
    private let onSelect: (MyActiveLogsType) -> Void

    // MARK: - Init

    public init(
        sectionType: MyPageSectionType = .myActiveLogs,
        onSelect: @escaping (MyActiveLogsType) -> Void
    ) {
        self.sectionType = sectionType
        self.onSelect = onSelect
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            SectionHeaderView(title: sectionType.rawValue, weight: .semibold)

            MyPageListCard {
                ForEach(MyActiveLogsType.allCases) { log in
                    if log != MyActiveLogsType.allCases.first {
                        MyPageListDivider()
                    }

                    MyPageListRow(
                        systemIcon: log.icon,
                        iconColor: log.backgroundColor,
                        title: log.rawValue,
                        action: { onSelect(log) }
                    )
                }
            }
        }
    }
}
