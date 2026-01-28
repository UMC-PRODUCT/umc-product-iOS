//
//  SectionHeaderView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/27/26.
//

import SwiftUI

/// Section의 헤더 타이틀을 표시하는 공통 뷰 컴포넌트
///
/// Form 또는 List의 섹션 헤더에서 일관된 스타일의 타이틀을 표시하기 위해 사용합니다.
///
/// - Example:
/// ```swift
/// Section(content: {
///     // content
/// }, header: {
///     SectionHeaderView(title: "설정")
/// })
/// ```
struct SectionHeaderView: View {
    // MARK: - Property

    /// 섹션 헤더에 표시할 타이틀 텍스트
    let title: String

    // MARK: - Body

    var body: some View {
        Text(title)
            .appFont(.bodyEmphasis, color: .black)
    }
}
