//
//  UMCPartTypeSeedColorTests.swift
//  CoreUIComponentsTests
//
//  Created by One on 8/18/26.
//

import SwiftUI
import Testing
import UIKit
import UMCFoundation
@testable import CoreUIComponents

@Suite("UMCPartType+SeedColor — 명함 파트 시드 컬러")
struct UMCPartTypeSeedColorTests {

    /// 명함첩 카드의 배경 그라데이션·칩 색이 전부 이 한 값에서 파생된다.
    /// 값이 틀어지면 시안과 어긋난 카드가 10종 전부 조용히 나가므로 hex 로 못 박는다.
    ///
    /// 신규 두 파트는 다이내믹 토큰(`yellow600`·`green700`)이라 라이트로 해석한 값이다 (#1359).
    private static let designSeeds: [(part: UMCPartType, hex: String)] = [
        (.admin, "6155F5"),
        (.design, "FF2D55"),
        (.pm, "CB30E0"),
        (.front(type: .web), "AC7F5E"),
        (.front(type: .android), "00C0E8"),
        (.front(type: .ios), "FF9500"),
        (.server(type: .spring), "34C759"),
        (.server(type: .node), "FFCC00"),
        (.webProductEngineer, "DC6803"),
        (.mobileProductEngineer, "2A8969"),
    ]

    /// 회색과 유채색을 가르는 채널폭 경계. 실측은 폴백 13(라이트)·22(다크) 대 시드 최소
    /// 78(Web) 이라 그 사이 어디를 잡아도 되고, 양쪽에 넉넉한 40 으로 둔다.
    private static let greyChannelSpreadLimit = 40

    /// WCAG AA 본문 기준.
    private static let minimumContrastRatio = 4.5

    @Test("파트마다 시안이 지정한 시드 컬러를 돌려준다", arguments: designSeeds)
    func seedColorMatchesDesign(seed: (part: UMCPartType, hex: String)) {
        #expect(seed.part.seedColor.srgbHex == seed.hex)
    }

    @Test("열 파트의 시드 컬러가 서로 겹치지 않는다")
    func seedColorsAreDistinct() {
        let hexes = Self.designSeeds.map(\.part.seedColor.srgbHex)

        #expect(Set(hexes).count == Self.designSeeds.count)
    }

    /// 못 읽은 파트는 `.admin` 으로 떨어져 Admin 인디고를 입던 자리다 (#1236). hex 완전
    /// 일치만 보면 폴백을 `6155F6`(Admin 에서 1비트) 로 옮겨도 통과하면서 「운영진처럼
    /// 보임」이 되살아나므로, **회색이라는 성질 자체**를 채널폭으로 못 박는다.
    @Test("미정의 파트 폴백은 저채도 회색이라 유채색 시드와 섞이지 않는다")
    func unresolvedSeedIsLowChromaGrey() {
        let fallback = UMCPartType.unresolvedSeedColor
        let hexes = Set(Self.designSeeds.map(\.part.seedColor.srgbHex))

        #expect(!hexes.contains(fallback.srgbHex))
        #expect(
            fallback.channelSpread < Self.greyChannelSpreadLimit,
            "폴백 채널폭 \(fallback.channelSpread)"
        )

        for seed in Self.designSeeds {
            #expect(
                seed.part.seedColor.channelSpread > Self.greyChannelSpreadLimit,
                "\(seed.part.name) 채널폭 \(seed.part.seedColor.channelSpread)"
            )
        }
    }

    /// 이 값이 흰 라벨(#1235, 8종 전부 미달)을 버리고 검정 라벨로 간 근거다. 시드나
    /// 혼합비를 건드리면 화면이 아니라 여기서 먼저 깨져야 한다. #1351 의 신규 두 파트도
    /// 같은 기준을 통과해야 색을 확정할 수 있다.
    @Test(
        "파트 칩 면 위 검정 라벨이 열 파트 전부 WCAG AA(4.5:1)를 넘는다",
        arguments: designSeeds
    )
    func chipSeedColorPassesBlackLabelContrast(seed: (part: UMCPartType, hex: String)) {
        let ratio = seed.part.chipSeedColor.blackContrastRatio

        #expect(ratio >= Self.minimumContrastRatio, "\(seed.part.name) 대비 \(ratio)")
    }

    /// 폴백만 다이내믹 토큰이라 모드에 따라 변한다 — 어느 모드로 해석되든 기준을 넘는다.
    @Test("못 읽은 파트 폴백 칩 면 위 검정 라벨도 같은 기준을 넘는다")
    func unresolvedChipSeedColorPassesBlackLabelContrast() {
        let ratio = UMCPartType.unresolvedChipSeedColor.blackContrastRatio

        #expect(ratio >= Self.minimumContrastRatio, "폴백 대비 \(ratio)")
    }

    /// `allCases` 는 `.admin` 을 빼고 9종만 담는다(운영진은 파트 선택 목록에 안 오른다).
    /// 명함은 운영진 카드도 그려야 하므로 그 9종을 덮되 admin 까지 별도로 확인한다.
    @Test("파트 선택 목록(allCases) 전체가 시드 컬러를 갖는다")
    func allSelectablePartsCovered() {
        let covered = Set(Self.designSeeds.map(\.part))

        #expect(UMCPartType.allCases.allSatisfy { covered.contains($0) })
        #expect(covered.contains(.admin))
    }
}

// MARK: - Token Chip

@Suite("UMCPartType+ChipTokens — 토큰 칩 면·잉크 대비")
struct UMCPartTypeChipTokenContrastTests {

    typealias ChipColors = (background: Color, foreground: Color)

    /// 칩 하나의 토큰 쌍과 실측값. hex 는 `잉크/면` 순서다.
    typealias TokenChip = (
        name: String,
        colors: ChipColors?,
        lightHex: String,
        darkHex: String,
        lightRatio: Double,
        darkRatio: Double
    )

    /// 시안이 토큰으로 확정한 칩 3종 (#1359). 인프라는 파트가 아니라 신규 두 파트에 얹는 배지다.
    private static let tokenChips: [TokenChip] = [
        (
            UMCPartType.webProductEngineer.name,
            UMCPartType.webProductEngineer.chipTokenColors,
            "DC6803/FFFBE5", "FDB022/5C3A00", 3.35, 5.54
        ),
        (
            UMCPartType.mobileProductEngineer.name,
            UMCPartType.mobileProductEngineer.chipTokenColors,
            "2A8969/EBF9F5", "96DFC6/174A39", 3.98, 6.59
        ),
        (
            UMCPartType.infraName,
            UMCPartType.infraChipColors,
            "DC6803/FFFBE5", "FDB022/5C3A00", 3.35, 5.54
        ),
    ]

    /// `잉크/면` hex. 두 값을 한 문자열로 맞대 실패 메시지 하나로 읽히게 한다.
    private static func hexPair(_ colors: ChipColors, in colorScheme: ColorScheme) -> String {
        colors.foreground.srgbHex(in: colorScheme) + "/"
            + colors.background.srgbHex(in: colorScheme)
    }

    /// 파트 칩은 `caption2`·`footnote` 라 소형 텍스트 기준(4.5:1)이 맞다.
    private static let minimumContrastRatio = 4.5

    /// WCAG AA Large(18pt·굵은 14pt 이상) 기준.
    private static let largeTextContrastRatio = 3.0

    /// 라이트 대비는 AA(4.5:1)에 **못 미친다** — 디자인팀 재조율 대기 항목이다 (#1359).
    ///
    /// 시드 칩 스위트처럼 4.5 를 요구하면 시안 값을 적용할 수 없고, 기준을 3.0 으로 낮추면
    /// 미달이 통과로 가려진다. 그래서 기준을 바꾸지 않고 **실측값 자체를 고정**한다.
    /// 재조율로 색이 바뀌면 여기서 먼저 깨진다 — 그때 이 테스트를 4.5 검증으로 옮긴다.
    @Test("라이트 대비는 실측값 그대로 AA Large 만 넘고 AA 에는 못 미친다", arguments: tokenChips)
    func lightContrastIsRecordedBelowAA(chip: TokenChip) throws {
        let colors = try #require(chip.colors, "\(chip.name) 토큰 쌍 없음")
        let ratio = colors.foreground.contrastRatio(with: colors.background, in: .light)

        #expect(Self.hexPair(colors, in: .light) == chip.lightHex, "\(chip.name)")
        #expect(ratio.roundedToHundredths == chip.lightRatio, "\(chip.name) 대비 \(ratio)")
        #expect(ratio >= Self.largeTextContrastRatio, "\(chip.name) 대비 \(ratio)")
        #expect(ratio < Self.minimumContrastRatio, "\(chip.name) 대비 \(ratio)")
    }

    @Test("다크 대비는 실측값 그대로 AA(4.5:1)를 넘는다", arguments: tokenChips)
    func darkContrastPassesAA(chip: TokenChip) throws {
        let colors = try #require(chip.colors, "\(chip.name) 토큰 쌍 없음")
        let ratio = colors.foreground.contrastRatio(with: colors.background, in: .dark)

        #expect(Self.hexPair(colors, in: .dark) == chip.darkHex, "\(chip.name)")
        #expect(ratio.roundedToHundredths == chip.darkRatio, "\(chip.name) 대비 \(ratio)")
        #expect(ratio >= Self.minimumContrastRatio, "\(chip.name) 대비 \(ratio)")
    }

    /// 토큰 쌍이 새면 그 파트는 시드 칩 AA 검증을 조용히 벗어난다. 시드 칩 8종을 묶어 둔다.
    @Test("토큰 칩은 신규 두 파트만 갖고, 나머지는 시드 칩 검증을 그대로 받는다")
    func onlyProductEngineersUseTokenChips() {
        for part in UMCPartType.allCases + [.admin] {
            #expect((part.chipTokenColors != nil) == part.canHaveInfra, "\(part.name)")
        }
    }
}

// MARK: - Test Helper

private extension Double {

    /// 이슈 표기(소수 둘째 자리)와 맞대기 위한 반올림.
    var roundedToHundredths: Double {
        (self * 100).rounded() / 100
    }
}

private extension Color {

    /// 다이내믹 토큰을 지정한 모드로 해석한 sRGB 8bit 채널.
    func srgbChannels(in colorScheme: ColorScheme) -> (red: Int, green: Int, blue: Int) {
        var environment = EnvironmentValues()
        environment.colorScheme = colorScheme
        let resolved = resolve(in: environment)
        return (
            Int((resolved.red * 255).rounded()),
            Int((resolved.green * 255).rounded()),
            Int((resolved.blue * 255).rounded())
        )
    }

    func srgbHex(in colorScheme: ColorScheme) -> String {
        let channels = srgbChannels(in: colorScheme)
        return String(format: "%02X%02X%02X", channels.red, channels.green, channels.blue)
    }

    /// WCAG 2.1 대비비 — 밝은 쪽 휘도를 분자로 둔다.
    func contrastRatio(with other: Color, in colorScheme: ColorScheme) -> Double {
        let luminances = [
            Self.relativeLuminance(of: srgbChannels(in: colorScheme)),
            Self.relativeLuminance(of: other.srgbChannels(in: colorScheme)),
        ]
        return ((luminances.max() ?? 0) + 0.05) / ((luminances.min() ?? 0) + 0.05)
    }
}

private extension Color {

    /// sRGB 8bit 채널. hex 비교·채널폭·대비 계산이 모두 이 한 값에서 나온다.
    var srgbChannels: (red: Int, green: Int, blue: Int) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (
            Int((red * 255).rounded()),
            Int((green * 255).rounded()),
            Int((blue * 255).rounded())
        )
    }

    /// sRGB 8bit 표기. 시안 hex 문자열과 직접 맞대려고 테스트에서만 쓴다.
    var srgbHex: String {
        let channels = srgbChannels
        return String(format: "%02X%02X%02X", channels.red, channels.green, channels.blue)
    }

    /// 최대 채널과 최소 채널의 차. 무채색에 가까울수록 0 에 붙는다.
    var channelSpread: Int {
        let channels = [srgbChannels.red, srgbChannels.green, srgbChannels.blue]
        return (channels.max() ?? 0) - (channels.min() ?? 0)
    }

    /// WCAG 2.1 상대 휘도.
    var relativeLuminance: Double {
        Self.relativeLuminance(of: srgbChannels)
    }

    static func relativeLuminance(of channels: (red: Int, green: Int, blue: Int)) -> Double {
        func linear(_ value: Int) -> Double {
            let normalized = Double(value) / 255
            return normalized <= 0.03928
                ? normalized / 12.92
                : pow((normalized + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(channels.red)
            + 0.7152 * linear(channels.green)
            + 0.0722 * linear(channels.blue)
    }

    /// 검정 잉크와의 대비비 — 검정 휘도가 0 이라 `(L + 0.05) / 0.05` 로 줄어든다.
    var blackContrastRatio: Double {
        (relativeLuminance + 0.05) / 0.05
    }
}
