//
//  SchoolSection.swift
//  AppProduct
//
//  Created by euijjang97 on 1/31/26.
//

import SwiftUI

/// 학교 정보를 표시하는 읽기 전용 섹션
///
/// 사용자의 소속 대학교 정보를 읽기 전용 필드로 표시합니다.
struct SchoolSection: View, Equatable {

    // MARK: - Property

    /// 대학교 이름
    let univ: String

    /// 섹션 헤더 타이틀
    let header: String

    // MARK: - Body

    var body: some View {
        ReadOnlyTextField(placeholder: univ, header: header)
    }
}
