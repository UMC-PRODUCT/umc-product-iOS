//
//  UMCPartType+Color.swift
//  CoreUIComponents
//
//  Created by 이예지 on 5/8/26.
//

import SwiftUI
import CoreDesignSystem
import UMCFoundation

extension UMCPartType {

    /// 우리가 못 읽은 파트(`MyCard.partRaw` 가 있는 경우)의 시드 폴백.
    ///
    /// `partRaw != nil` 이면 `part` 가 관례상 `.admin` 으로 떨어져 Admin 인디고(#6155F5)로
    /// 칠해지던 버그를 막는다. 채널폭 13 의 저채도 회색이라 유채색 시드 10종(채널폭 최소 78)
    /// 과 섞이지 않는다 (#1236 확정, #1351 에서 2종 추가).
    ///
    /// - Note: 시드 컬러 칩을 쓰는 8종과 달리 이 값은 다이내믹 토큰이라 모드에 따라 변한다
    ///   (light `#B2B8BF` / dark `#7C8792`). 칩 면이 모드 불변이라는 전제의 예외지만,
    ///   검정 라벨 대비가 라이트 12.22 · 다크 7.82 로 양쪽 다 AA 를 넘어 잉크는 그대로 둔다.
    public static let unresolvedSeedColor: Color = .grey400

    /// ``unresolvedSeedColor`` 의 칩 면 — 시드 10종과 같은 혼합 규칙(``chipSeedColor``)을 탄다.
    public static var unresolvedChipSeedColor: Color {
        unresolvedSeedColor.mix(with: .white, by: chipWhiteMix, in: .device)
    }

    /// 칩 면을 만들 때 시드에 섞는 흰색 비율. 폴백까지 같은 규칙을 타야 하므로 여기 한 곳에 둔다.
    private static let chipWhiteMix: Double = 0.2

    /// 명함 시드 컬러 — 시안이 raw hex 로 지정한 파트 브랜드 색.
    ///
    /// ``color`` 와 **일부러 분리해 둔다.** ``color`` 는 SwiftUI 시스템 컬러라
    /// Activity·Notice 가 이미 그 값으로 화면을 그리고 있고, 시안 hex 와는 4종이
    /// 어긋난다(Admin·PM·Web·Android). 여기서 ``color`` 를 시안 값으로 갈아끼우면
    /// 명함과 무관한 남의 화면 색이 같이 바뀐다.
    ///
    /// 명함첩 카드는 배경 그라데이션 2겹과 칩 2개가 전부 이 한 값에서 파생된다.
    ///
    /// - Note: iOS 파트만 시안에 변형이 없어(7종) `systemOrange` 로 채웠다.
    ///   나머지 7종이 iOS 시스템 팔레트 계열이고 주황이 비어 있어 충돌하지 않는다.
    ///   #1236 에서 현행 유지로 확정했다. 공식 iOS 변형 색이 오면 이 한 값과
    ///   `UMCPartTypeSeedColorTests` 만 교체한다.
    ///
    /// - Note: 신규 두 파트는 디자인이 토큰으로 확정한 칩 잉크 색(``chipTokenColors``)을
    ///   시드로 쓴다 — Web PE `yellow600`, Mobile PE `green700`
    ///   (#1359). #1351 의 임시 `systemBlue`·`systemMint` 를 대체한다. 이 둘만 다이내믹
    ///   토큰이라 카드 워시가 모드를 따라 바뀌지만, 칩은 시드 면 대신 토큰 쌍을 그려
    ///   모드 불변 전제가 필요 없다.
    public var seedColor: Color {
        switch self {
        case .admin:
            return Color(red: 97 / 255, green: 85 / 255, blue: 245 / 255)
        case .pm:
            return Color(red: 203 / 255, green: 48 / 255, blue: 224 / 255)
        case .design:
            return Color(red: 255 / 255, green: 45 / 255, blue: 85 / 255)
        case .server(let type):
            switch type {
            case .spring:
                return Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)
            case .node:
                return Color(red: 255 / 255, green: 204 / 255, blue: 0 / 255)
            }
        case .front(let type):
            switch type {
            case .web:
                return Color(red: 172 / 255, green: 127 / 255, blue: 94 / 255)
            case .android:
                return Color(red: 0 / 255, green: 192 / 255, blue: 232 / 255)
            case .ios:
                return Color(red: 255 / 255, green: 149 / 255, blue: 0 / 255)
            }
        case .webProductEngineer:
            return .yellow600
        case .mobileProductEngineer:
            return .green700
        }
    }

    /// 명함_s 파트·기수 칩의 **면** 색 — 시드에 흰색을 섞어 굳힌 불투명색.
    ///
    /// 알파 합성(시드@0.8)을 쓰지 않는 이유는 라이트·다크에서 같은 색으로 남기기 위해서다.
    /// 칩 라벨이 모드 불변인 `Color.black` 고정이라 면도 모드 불변이어야 한다 — 라벨 색만
    /// 바꾸는 안은 다크에서 다시 깨진다(검정 라벨: Admin 2.95·PM 3.47·Design 3.90·Web 4.08
    /// 미달 / 흰 라벨: Spring 3.42·Android 3.32·iOS 3.38·Node 2.39 미달, #1235 실측).
    ///
    /// 이 값 위의 검정 라벨은 10종 전부 **5.92~14.92** 로 WCAG AA(4.5:1)를 통과한다 —
    /// `UMCPartTypeSeedColorTests` 가 고정한다 (#1236 확정).
    ///
    /// - Note: ``chipTokenColors`` 가 있는 파트는 칩에 이 값 대신 토큰 쌍을 쓴다 (#1359).
    public var chipSeedColor: Color {
        seedColor.mix(with: .white, by: Self.chipWhiteMix, in: .device)
    }

    /// 디자인이 토큰으로 확정한 파트 칩의 면·잉크 쌍. 확정되지 않은 파트는 `nil` 이다.
    ///
    /// 시드 면 + 검정 잉크(``chipSeedColor``)와 달리 면과 잉크가 **둘 다 다이내믹 토큰**이라
    /// 라이트·다크가 함께 뒤집힌다 (#1359).
    ///
    /// - Warning: 라이트 대비가 WCAG AA 소형 텍스트(4.5:1)에 못 미친다 — 웹 3.35 · 모바일
    ///   3.98 (다크는 5.54 · 6.59 로 통과). 디자인팀 재조율 대기 중이며 값은 시안 그대로다.
    ///   `UMCPartTypeSeedColorTests` 의 토큰 칩 스위트가 이 측정값을 고정한다.
    public var chipTokenColors: (background: Color, foreground: Color)? {
        switch self {
        case .webProductEngineer:    return (.yellow100, .yellow600)
        case .mobileProductEngineer: return (.green100, .green700)
        default:                     return nil
        }
    }

    /// 인프라 겸직 배지(``UMCPartType/infraName``)의 면·잉크 쌍 — 시안이 Web PE 와
    /// 같은 yellow 계열로 줬다 (#1359).
    public static let infraChipColors: (background: Color, foreground: Color) = (
        .yellow100, .yellow600
    )

    /// 파트별 고유 색상
    public var color: Color {
        switch self {
        case .admin:
            return .indigo
        case .pm:
            return .purple
        case .design:
            return .pink
        case .server(let type):
            switch type {
            case .spring: return .green
            case .node:   return .yellow
            }
        case .front(let type):
            switch type {
            case .web:     return .brown
            case .android: return .teal
            case .ios:     return .orange
            }
        case .webProductEngineer:    return .yellow600
        case .mobileProductEngineer: return .green700
        }
    }
}
