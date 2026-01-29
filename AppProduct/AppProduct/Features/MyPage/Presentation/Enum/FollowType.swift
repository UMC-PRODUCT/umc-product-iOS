//
//  FollowType.swift
//  AppProduct
//
//  Created by euijjang97 on 1/29/26.
//

import Foundation
import SwiftUI

/// UMC 소셜 미디어 채널 타입
///
/// 마이페이지에서 표시되는 UMC 공식 채널 링크를 정의합니다.
enum FollowType: String, CaseIterable {
    /// Instagram 공식 계정
    case instagram
    /// UMC 공식 웹사이트
    case webSite

    /// 웹 브라우저용 URL
    ///
    /// - Returns: 각 채널의 웹 URL 주소
    var url: String {
        switch self {
        case .instagram:
            return "https://www.instagram.com/uni_makeus_challenge/"
        case .webSite:
            return "https://umc.makeus.in"
        }
    }

    /// 앱 딥링크용 URL Scheme
    ///
    /// Instagram의 경우 앱이 설치되어 있으면 앱으로 직접 이동할 수 있도록 URL Scheme을 제공합니다.
    ///
    /// - Returns: 앱 URL Scheme (없는 경우 nil)
    ///
    /// - Note: Instagram URL Scheme 사용을 위해 Info.plist에 `LSApplicationQueriesSchemes`에 "instagram" 등록 필요
    var appURL: String? {
        switch self {
        case .instagram:
            return "instagram://user?username=uni_makeus_challenge"
        case .webSite:
            return nil
        }
    }

    /// 채널 아이콘 이미지
    ///
    /// - Returns: Assets에 등록된 ImageResource
    var icon: ImageResource {
        switch self {
        case .instagram:
            return .instagram
        case .webSite:
            return .umcLogo
        }
    }
}
