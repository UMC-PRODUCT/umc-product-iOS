//
//  ConnectionSocial.swift
//  AppProduct
//
//  Created by euijjang97 on 1/31/26.
//

import SwiftUI

/// 연동된 소셜 계정 목록을 보여주는 섹션
///
/// 사용자가 연동한 소셜 로그인 서비스(Google, Kakao, Apple 등)를
/// 태그 형태로 표시합니다.
struct ConnectionSocial: View, Equatable {

    // MARK: - Property

    /// 연동된 소셜 계정 타입 배열
    let socialConnected: [SocialType]

    /// 섹션 헤더 타이틀
    let header: String

    // MARK: - Body

    var body: some View {
        Section {
            socialTagView
        } header: {
            SectionHeaderView(title: header)
        }
    }

    /// 소셜 계정 태그들을 가로로 나열하는 컨테이너
    private var socialTagView: some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            ForEach(socialConnected, id: \.rawValue) { social in
                socialType(social)
            }
        }
    }

    /// 개별 소셜 타입 태그 뷰
    ///
    /// 각 소셜 서비스별 브랜드 컬러와 아이콘을 적용한 태그를 생성합니다.
    ///
    /// - Parameter social: 소셜 타입 (Google, Kakao, Apple 등)
    /// - Returns: 스타일이 적용된 태그 뷰
    private func socialType(_ social: SocialType) -> some View {
        Text(social.rawValue)
            .appFont(.caption1Emphasis, color: social.fontColor)
            .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            .glassEffect(.clear.tint(social.color), in: .containerRelative)
    }
}
