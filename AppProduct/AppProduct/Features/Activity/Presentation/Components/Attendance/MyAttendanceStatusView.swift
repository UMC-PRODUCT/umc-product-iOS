//
//  MyAttendanceStatusView.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/22/26.
//

import SwiftUI

// MARK: - MyAttendanceStatusView

/// 나의 출석 현황 섹션
struct MyAttendanceStatusView: View {
    // MARK: - Property

    private let models: [MyAttendanceItemModel]

    // MARK: - Init

    /// - Parameters:
    ///   - sessions: 전체 세션 목록 (pending 상태는 내부에서 필터링)
    ///   - categoryFor: 제목으로 카테고리 조회 (ViewModel에서 제공)
    init(sessions: [Session], categoryFor: (String) -> ScheduleIconCategory) {
        // pending 상태 제외, 완료된 출석만 표시
        self.models = sessions.compactMap { session in
            let category = categoryFor(session.info.title)
            return MyAttendanceItemModel(from: session, category: category)
        }
    }
    
    // MARK: - Constant

    private enum Constant {
        static let listSpacing: CGFloat = 0
    }


    // MARK: - Body

    var body: some View {
        attendanceList
    }
    
    private var attendanceList: some View {
        LazyVStack(spacing: Constant.listSpacing) {
            ForEach(models, id: \.id) { model in
                MyAttendanceCard(model: model)

                // 마지막 아이템이 아닐 때만 Divider
                if model.id != models.last?.id {
                    Divider()
                }
            }
        }
        .clipShape(ConcentricRectangle(corners: .concentric(minimum: DefaultConstant.concentricRadius), isUniform:  true))
        .glass()
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    ZStack {
        Color.grey100.ignoresSafeArea()

        MyAttendanceStatusView(
            sessions: AttendancePreviewData.sessions,
            categoryFor: { _ in .general }  // Preview용 기본값
        )
    }
    .frame(height: 600)
}
