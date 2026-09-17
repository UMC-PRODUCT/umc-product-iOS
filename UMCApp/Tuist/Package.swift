// swift-tools-version: 6.0
//
//  Package.swift
//  UMCApp
//
//  Created by euijjang97 on 3/6/26.
//

import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings
    import struct ProjectDescription.Settings

    /// macOS·Catalyst 전용 소스는 iOS 빌드에서 `#if` 로 전부 빠져 빈 `.o` 가 된다.
    /// staticFramework 를 묶는 libtool 이 그 빈 오브젝트마다 `has no symbols` 경고를 내므로
    /// 서드파티 타겟에서만 끈다(#1394). dynamic 으로 바꾸면 #1340 의 `-ObjC` 링크 문제와 얽힌다.
    private let silencedNoSymbolsWarning: Settings = .settings(
        base: ["OTHER_LIBTOOLFLAGS": "$(inherited) -no_warning_for_no_symbols"]
    )

    let packageSettings = PackageSettings(
        // Customize the product types for specific package product
        // Default is .staticFramework
        // productTypes: ["Alamofire": .framework,]
        productTypes: [:],
        targetSettings: [
            "AppAuth": silencedNoSymbolsWarning,
            "AppCheckCore": silencedNoSymbolsWarning,
            "Firebase": silencedNoSymbolsWarning,
        ]
    )
#endif

let package = Package(
    name: "UMCApp",
    dependencies: [
        .package(url: "https://github.com/Moya/Moya.git", from: "15.0.3"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.6.1"),
        .package(url: "https://github.com/kakao/kakao-ios-sdk", from: "2.27.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "9.1.0"),
        // FCM 푸시(FirebaseCore·FirebaseMessaging). 킬스위치·강제 업데이트는 GitHub Pages
        // 원격 설정으로 옮겨 RemoteConfig를 쓰지 않는다(#1389).
        // AppProduct(레거시)에서 검증된 버전(12.7.0)을 하한으로 하는 same-major 범위
        // (from:, 다른 패키지들과 동일한 버전 지정 스타일).
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.7.0"),
    ]
)
