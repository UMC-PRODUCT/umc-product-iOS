//
//  ReadOnlyText.swift
//  AppProduct
//
//  Created by euijjang97 on 1/31/26.
//

import SwiftUI

/// 읽기 전용 텍스트 필드 컴포넌트
///
/// 사용자 정보 중 수정 불가능한 항목(예: 이름, 학교)을 표시할 때 사용합니다.
/// TextField를 disabled 상태로 설정하여 읽기 전용 모드로 동작합니다.
struct ReadOnlyTextField: View, Equatable {

    // MARK: - Property

    /// 필드에 표시될 텍스트 (placeholder로 표현)
    let placeholder: String

    /// 섹션 헤더 타이틀
    let header: String

    // MARK: - Body

    var body: some View {
        Section {
            TextField("", text: .constant(""), prompt: Text(placeholder))
                .disabled(true) // 읽기 전용 모드
        } header: {
            SectionHeaderView(title: header)
        }
    }
}
