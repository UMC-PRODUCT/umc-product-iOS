//
//  GenAndPartSection.swift
//  AppProduct
//
//  Created by euijjang97 on 1/31/26.
//

import SwiftUI

/// 기수와 파트 정보를 표시하는 읽기 전용 섹션
///
/// UMC 활동 기수와 소속 파트를 "N기/파트명" 형식으로 함께 표시합니다.
struct GenAndPartSection: View, Equatable {

    // MARK: - Property

    /// UMC 활동 기수 (예: 11, 12)
    let gen: Int

    /// 소속 파트 (Web, iOS, Android 등)
    let part: UMCPartType

    /// 섹션 헤더 타이틀
    let header: String

    // MARK: - Body

    var body: some View {
        ReadOnlyTextField(placeholder: "\(gen)기/\(part.name)", header: header)
    }
}
