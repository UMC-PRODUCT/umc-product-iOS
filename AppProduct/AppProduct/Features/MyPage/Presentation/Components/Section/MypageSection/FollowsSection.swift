//
//  FollowsSection.swift
//  AppProduct
//
//  Created by euijjang97 on 1/29/26.
//

import SwiftUI

/// UMC 소셜 미디어 채널 버튼 섹션
///
/// Instagram, 웹사이트 등 UMC의 공식 채널로 이동할 수 있는 버튼들을 표시합니다.
///
/// - Note: Instagram의 경우 앱이 설치되어 있으면 앱으로, 없으면 웹으로 자동 연결됩니다.
struct FollowsSection: View {
    // MARK: - Property

    @Environment(\.openURL) private var openURL

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing24, content: {
            SectionHeaderView(title: "UMC 외부 채널")
            btnContent
        })
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .listRowInsets(EdgeInsets())
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Function

    private var btnContent: some View {
        HStack(spacing: DefaultSpacing.spacing12, content: {
            ForEach(FollowType.allCases, id: \.self) { follow in
                Button(action: {
                    openSocialMedia(follow)
                }, label: {
                    Image(follow.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .clipShape(.circle)
                        .glassEffect(.clear.interactive(), in: .circle)
                })
            }
        })
    }

    /// 소셜 미디어 URL 열기
    ///
    /// Instagram의 경우 URL Scheme을 사용하여 앱이 설치되어 있으면 앱으로 열고,
    /// 설치되어 있지 않으면 웹 브라우저로 폴백합니다.
    ///
    /// - Parameter follow: 열고자 하는 소셜 미디어 타입
    ///
    /// - Note: Instagram URL Scheme 사용을 위해 Info.plist에 `LSApplicationQueriesSchemes`에 "instagram" 등록 필요
    private func openSocialMedia(_ follow: FollowType) {
        switch follow {
        case .instagram:
            // Instagram 앱 URL Scheme 시도
            let appURL = URL(string: follow.appURL ?? "")
            let webURL = URL(string: follow.url)

            if let appURL = appURL, UIApplication.shared.canOpenURL(appURL) {
                // Instagram 앱이 설치되어 있으면 앱으로 열기
                openURL(appURL)
            } else if let webURL = webURL {
                // 앱이 없으면 Safari로 웹 페이지 열기
                openURL(webURL)
            }
        case .webSite:
            // 웹사이트는 바로 열기
            if let url = URL(string: follow.url) {
                openURL(url)
            }
        }
    }
}

#Preview {
    FollowsSection()
}
