//
//  TypographyTokens.swift
//  AppProduct
//
//  Created by jaewon Lee on 2026-01-01.
//

/*
 # Typography Tokens
 
 앱 전체의 타이포그래피 디자인 시스템을 정의합니다.
 Pretendard 폰트를 기반으로 하며, Figma 디자인 시스템과 일치합니다.
 
 ---
 
 ## 사용 가이드
 
 ### 1. 기본 사용법
 
 가장 간단한 사용 방법입니다. Emphasis 스타일은 자동으로 Bold가 적용됩니다.
 
 ```swift
 Text("안녕하세요")
 .appFont(.body)  // Pretendard-Regular, 16pt
 
 Text("강조된 제목")
 .appFont(.title1Emphasis)  // Pretendard-Bold, 28pt (자동으로 Bold 적용)
 ```
 
 ### 2. 색상 지정
 
 텍스트 색상을 함께 지정할 수 있습니다.
 
 ```swift
 Text("회색 본문")
 .appFont(.body, color: .gray)
 
 Text("파란색 제목")
 .appFont(.headline, color: .blue)
 ```
 
 ### 3. Weight 명시적 지정
 
 자동 적용되는 weight 대신 명시적으로 지정할 수 있습니다.
 
 ```swift
 Text("일반 제목을 Bold로")
 .appFont(.title1, weight: .bold)
 
 Text("Emphasis를 Regular로 (드문 경우)")
 .appFont(.headlineEmphasis, weight: .regular)
 ```
 
 ### 4. 색상과 Weight 모두 지정
 
 ```swift
 Text("빨간색 Bold 텍스트")
 .appFont(.body, weight: .bold, color: .red)
 ```
 
 ### 5. Font만 사용 (lineSpacing 없이)
 
 특수한 경우 Font만 필요할 때는 Font Extension을 사용합니다.
 
 ```swift
 Text("Line spacing 없이")
 .font(.app(.body))
 
 Text("커스텀 사이즈")
 .font(.app(size: 20, weight: .bold))
 ```
 
 ---
 
 ## 타이포그래피 스케일
 
 | 스타일 | 사이즈 | 용도 |
 |--------|--------|------|
 | `.largeTitle` / `.largeTitleEmphasis` | 34pt | 큰 제목 |
 | `.title1` / `.title1Emphasis` | 28pt | 주요 제목 |
 | `.title2` / `.title2Emphasis` | 22pt | 부제목 |
 | `.title3` / `.title3Emphasis` | 20pt | 작은 제목 |
 | `.headline` / `.headlineEmphasis` | 17pt | 헤드라인 |
 | `.body` / `.bodyEmphasis` | 16pt / 17pt | 본문 |
 | `.callout` / `.calloutEmphasis` | 16pt | 강조 본문 |
 | `.subheadline` / `.subheadlineEmphasis` | 15pt | 부제 |
 | `.footnote` / `.footnoteEmphasis` | 13pt | 각주 |
 | `.caption1` / `.caption1Emphasis` | 12pt | 캡션 |
 | `.caption2` / `.caption2Emphasis` | 11pt | 작은 캡션 |
 
 ---
 
 ## 주의사항
 
 - Line spacing은 자동으로 계산됩니다 (lineHeight - size)
 - Emphasis 스타일은 자동으로 Bold가 적용되므로, 별도로 weight를 지정할 필요가 없습니다
 - 커스텀 폰트가 프로젝트에 등록되어 있어야 합니다 (Pretendard-Regular.otf, Pretendard-Bold.otf)
 
 */

import SwiftUI

// MARK: - AppFont
enum AppFont {
    case largeTitle
    case title1
    case title2
    case title3
    case body
    case callout
    case subheadline
    case footnote
    case caption1
    case caption2
    
    case largeTitleEmphasis
    case title1Emphasis
    case title2Emphasis
    case title3Emphasis
    case bodyEmphasis
    case calloutEmphasis
    case subheadlineEmphasis
    case footnoteEmphasis
    case caption1Emphasis
    case caption2Emphasis
    
    // MARK: - Base Style
    
    /// Emphasis 케이스의 기본 스타일 반환
    private var baseStyle: AppFont {
        switch self {
        case .largeTitleEmphasis: return .largeTitle
        case .title1Emphasis:     return .title1
        case .title2Emphasis:     return .title2
        case .title3Emphasis:     return .title3
        case .bodyEmphasis:       return .body
        case .calloutEmphasis:    return .callout
        case .subheadlineEmphasis: return .subheadline
        case .footnoteEmphasis:   return .footnote
        case .caption1Emphasis:   return .caption1
        case .caption2Emphasis:   return .caption2
        default:                  return self
        }
    }
    
    /// Emphasis 여부 확인
    var isEmphasis: Bool {
        switch self {
        case .largeTitleEmphasis, .title1Emphasis, .title2Emphasis, .title3Emphasis,
                .bodyEmphasis, .calloutEmphasis, .subheadlineEmphasis,
                .footnoteEmphasis, .caption1Emphasis, .caption2Emphasis:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Size
    
    var size: CGFloat {
        switch self {
        case .largeTitle, .largeTitleEmphasis:
            return 34
        case .title1, .title1Emphasis:
            return 28
        case .title2, .title2Emphasis:
            return 22
        case .title3, .title3Emphasis:
            return 20
        case .body:
            return 17
        case .bodyEmphasis:
            return 17
        case .callout, .calloutEmphasis:
            return 16
        case .subheadline, .subheadlineEmphasis:
            return 15
        case .footnote, .footnoteEmphasis:
            return 13
        case .caption1, .caption1Emphasis:
            return 12
        case .caption2, .caption2Emphasis:
            return 11
        }
    }
    
    // MARK: - Line Height Multiplier
    
    var lineHeightMultiplier: CGFloat {
        switch baseStyle {
        case .largeTitle:  return 1.21
        case .title1:      return 1.21
        case .title2:      return 1.27
        case .title3:      return 1.25
        case .body:        return 1.38
        case .callout:     return 1.31
        case .subheadline: return 1.33
        case .footnote:    return 1.38
        case .caption1:    return 1.33
        case .caption2:    return 1.18
        default:           return 1.0
        }
    }
    
    // MARK: - Computed Line Height
    
    var lineHeight: CGFloat {
        size * lineHeightMultiplier
    }
    
    // MARK: - Line Spacing
    
    var lineSpacing: CGFloat {
        lineHeight - size
    }
}

// MARK: - AppFontWeight

enum AppFontWeight {
    case regular
    case medium
    case semibold
    
    var fontName: String {
        switch self {
        case .regular:   return "Pretendard-Regular"
        case .medium:    return "Pretendard-Medium"
        case .semibold:      return "Pretendard-SemiBold"
        }
    }
    
    var swiftUIWeight: Font.Weight {
        switch self {
        case .regular:   return .regular
        case .medium:    return .medium
        case .semibold:      return .semibold
        }
    }
}

// MARK: - Font Extension

/*
 Font Extension 사용 예시:
 
 ```swift
 // 스타일 기반 폰트 (lineSpacing 미포함)
 Text("제목")
 .font(.app(.title1))
 
 // Weight 지정
 Text("굵은 제목")
 .font(.app(.title1, weight: .bold))
 
 // 커스텀 사이즈
 Text("20pt 텍스트")
 .font(.app(size: 20))
 
 Text("20pt Bold 텍스트")
 .font(.app(size: 20, weight: .bold))
 ```
 */
extension Font {
    
    /// Pretendard 기반 앱 폰트
    /// - Parameters:
    ///   - style: 타이포그래피 스타일
    ///   - weight: 폰트 굵기 (기본: emphasis 스타일이면 bold, 아니면 regular)
    /// - Returns: 설정된 Font
    static func app(_ style: AppFont, weight: AppFontWeight? = nil) -> Font {
        let finalWeight = weight ?? (style.isEmphasis ? .semibold : .regular)
        return .custom(finalWeight.fontName, size: style.size)
    }
    
    /// Pretendard 기반 커스텀 사이즈 폰트
    /// - Parameters:
    ///   - size: 폰트 사이즈
    ///   - weight: 폰트 굵기 (기본: regular)
    /// - Returns: 설정된 Font
    static func app(size: CGFloat, weight: AppFontWeight = .medium) -> Font {
        .custom(weight.fontName, size: size)
    }
}

// MARK: - View Extension

/*
 View Extension 사용 예시:
 
 ```swift
 // 기본 사용 (lineSpacing 자동 적용)
 Text("본문 텍스트")
 .appFont(.body)
 
 // Emphasis 스타일 (자동으로 Bold 적용)
 Text("강조된 제목")
 .appFont(.title1Emphasis)
 
 // 색상만 지정
 Text("회색 텍스트")
 .appFont(.body, color: .gray)
 
 // Weight만 지정
 Text("굵은 본문")
 .appFont(.body, weight: .bold)
 
 // 색상과 Weight 모두 지정
 Text("빨간 굵은 텍스트")
 .appFont(.headline, weight: .bold, color: .red)
 
 // 실전 예시
 VStack(alignment: .leading, spacing: 16) {
 Text("앱 타이포그래피")
 .appFont(.title1Emphasis)
 
 Text("Pretendard 폰트 기반 디자인 시스템")
 .appFont(.body, color: .gray)
 
 Text("자세히 보기")
 .appFont(.callout, weight: .bold, color: .blue)
 }
 ```
 */
extension View {
    
    /// 앱 타이포그래피 스타일 적용 (lineSpacing 포함)
    /// - Parameters:
    ///   - style: 타이포그래피 스타일
    ///   - weight: 폰트 굵기 (기본: emphasis 스타일이면 bold, 아니면 regular)
    ///   - color: 텍스트 색상 (선택)
    /// - Returns: 스타일이 적용된 View
    @ViewBuilder
    func appFont(
        _ style: AppFont,
        weight: AppFontWeight? = nil,
        color: Color? = nil
    ) -> some View {
        let view = self
            .font(.app(style, weight: weight))
            .lineSpacing(style.lineSpacing)
        if let color = color {
            view.foregroundStyle(color)
        } else {
            view
        }
    }
}
