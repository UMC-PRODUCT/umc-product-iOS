//
//  Nickanma.swift
//  AppProduct
//
//  Created by euijjang97 on 1/31/26.
//

import SwiftUI

/// 이름 및 닉네임 정보를 표시하는 읽기 전용 섹션
///
/// 실명과 닉네임을 각각 별도 섹션으로 표시합니다.
struct NameAndNickname: View, Equatable {

    // MARK: - Property

    /// 사용자 실명
    let name: String

    /// 사용자 닉네임
    let nickaname: String

    // MARK: - Body

    var body: some View {
        Group {
            ReadOnlyTextField(
                placeholder: name,
                header: "이름"
            )
            ReadOnlyTextField(
                placeholder: nickaname,
                header: "닉네임"
            )
        }
    }
}
