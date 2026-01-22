//
//  MyAttendanceStatusView.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/22/26.
//

import SwiftUI

// MARK: - Constant

private enum Constant {
    static let sectionSpacing: CGFloat = 16
    static let itemSpacing: CGFloat = 8
    static let horizontalPadding: CGFloat = 16
}

// MARK: - MyAttendanceStatusView

/// 나의 출석 현황 섹션
struct MyAttendanceStatusView: View {
    // MARK: - Property

    private let models: [MyAttendanceItemModel]

    // MARK: - Init

    /// - Parameter sessions: 전체 세션 목록 (pending 상태는 내부에서 필터링)
    init(sessions: [Session]) {
        // pending 상태 제외, 완료된 출석만 표시
        self.models = sessions.compactMap { MyAttendanceItemModel(from: $0) }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Constant.sectionSpacing) {
            // 섹션 헤더
            Text("나의 출석 현황")
                .appFont(.title3Emphasis, color: .grey800)

            // 출석 리스트
            VStack(spacing: Constant.itemSpacing) {
                ForEach(models) { model in
                    MyAttendanceCard(model: model)
                }
            }
        }
        .padding(.horizontal, Constant.horizontalPadding)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color.grey100.ignoresSafeArea()

        MyAttendanceStatusView(
            sessions: AttendancePreviewData.sessions
        )
    }
}
#endif
