//
//  StudyManagementLoadingView.swift
//  ActivityPresentation
//
//  Created by jaewon Lee on 8/10/26.
//

import CoreDesignSystem
import SwiftUI

// MARK: - StudyManagementLoadingView

/// 운영진 스터디 관리의 전체 영역 로딩 표시
struct StudyManagementLoadingView: View {

    // MARK: - Property

    /// 로딩 중임을 설명하는 안내 문구
    let message: String

    // MARK: - Body

    var body: some View {
        VStack(spacing: DefaultSpacing.spacing12) {
            ProgressView()
                .controlSize(.large)
                .tint(Color.grey500)

            Text(message)
                .appFont(.subheadline, color: .grey500)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
    }
}

// MARK: - StudyManagementLoadMoreIndicator

/// 리스트 하단의 다음 페이지 로딩 표시
struct StudyManagementLoadMoreIndicator: View {

    // MARK: - Body

    var body: some View {
        ProgressView()
            .tint(Color.grey500)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DefaultSpacing.spacing8)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("스터디 관리 로딩") {
    VStack(spacing: DefaultSpacing.spacing24) {
        StudyManagementLoadingView(message: "스터디 그룹 관리 불러오는 중...")

        StudyManagementLoadMoreIndicator()
    }
}
#endif
