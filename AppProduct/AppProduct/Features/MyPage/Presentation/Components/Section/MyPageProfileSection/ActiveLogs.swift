//
//  ActiveLogs.swift
//  AppProduct
//
//  Created by euijjang97 on 1/31/26.
//

import SwiftUI

/// 활동 이력 목록을 보여주는 섹션
///
/// 사용자의 UMC 활동 내역(스터디, 프로젝트 등)을 리스트 형태로 표시합니다.
/// 각 이력은 ActiveLogRow 컴포넌트를 통해 렌더링됩니다.
struct ActiveLogs: View, Equatable {

    // MARK: - Property

    /// 활동 이력 데이터 배열
    let rows: [ActivityLog]

    /// 섹션 헤더 타이틀
    let header: String

    // MARK: - Init

    init(rows: [ActivityLog], header: String) {
        self.rows = rows
        self.header = header
    }

    // MARK: - Body

    var body: some View {
        Section(content: {
            VStack(spacing: DefaultSpacing.spacing16, content: {
                ForEach(rows, id: \.id) { row in
                    ActiveLogRow(row: row)
                        .equatable() // Container-Presenter 패턴으로 렌더링 최적화
                }
            })
        }, header: {
            SectionHeaderView(title: header)
        })
    }
}
