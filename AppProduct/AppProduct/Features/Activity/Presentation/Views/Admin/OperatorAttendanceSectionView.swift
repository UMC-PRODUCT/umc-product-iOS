//
//  OperatorAttendanceSectionView.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/23/26.
//

import SwiftUI

/// Admin 모드의 출석 관리 섹션
///
/// 운영진이 출석을 관리하고 승인하는 화면입니다.
struct OperatorAttendanceSectionView: View {
    private let container: DIContainer
    private let errorHandler: ErrorHandler

    init(container: DIContainer, errorHandler: ErrorHandler) {
        self.container = container
        self.errorHandler = errorHandler
    }

    var body: some View {
        ScrollView {
            ContentUnavailableView {
                Label("출석 관리", systemImage: "checkmark.circle.badge.questionmark")
            } description: {
                Text("세션별 출석 현황을 관리하고 승인 대기 중인 요청을 처리합니다")
            }
            .safeAreaPadding(.vertical, DefaultConstant.defaultSafeBottom)
        }
    }
}

#Preview {
    OperatorAttendanceSectionView(
        container: AttendancePreviewData.container,
        errorHandler: AttendancePreviewData.errorHandler
    )
}
