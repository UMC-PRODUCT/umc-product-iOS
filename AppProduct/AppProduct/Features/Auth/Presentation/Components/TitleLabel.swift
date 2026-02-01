//
//  TitleLabel.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import SwiftUI

/// 폼 입력 필드의 제목 레이블
///
/// 제목 텍스트와 필수 입력 표시(*)를 함께 표시하는 컴포넌트입니다.
/// FormTextField, FormEmailField, FormPickerField 등에서 공통으로 사용됩니다.
struct TitleLabel: View {

    // MARK: - Property

    /// 표시할 제목 텍스트
    let title: String

    /// 필수 입력 여부 (true일 경우 빨간색 * 표시)
    let isRequired: Bool

    // MARK: - Constant

    /// 레이아웃 상수
    private enum Constants {
        /// 타이틀 간격 (현재 미사용)
        static let titleSpacing: CGFloat = 2
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: DefaultSpacing.spacing4, content: {
            // 제목 텍스트 (Bold, 18pt)
            Text(title)
                .font(.system(size: 18))
                .fontWeight(.heavy)

            // 필수 입력 표시
            if isRequired {
                Text("*")
                    .appFont(.body, color: .red)
            }
        })
        .padding(.leading, 12)
    }
}
