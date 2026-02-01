//
//  Nickanma.swift
//  AppProduct
//
//  Created by euijjang97 on 1/31/26.
//

import SwiftUI

/// 이름 및 닉네임 정보를 표시하는 읽기 전용 섹션
///
/// 실명과 닉네임을 "이름/닉네임" 형식으로 함께 표시합니다.
struct NameAndNickname: View, Equatable {

    // MARK: - Property

    /// 사용자 실명
    let name: String

    /// 사용자 닉네임
    let nickaname: String

    /// 섹션 헤더 타이틀
    let header: String

    // MARK: - Body

    var body: some View {
        ReadOnlyTextField(
            placeholder: "\(name)/\(nickaname)",
            header: header
        )
    }
}
