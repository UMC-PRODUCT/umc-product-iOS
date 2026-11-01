//
//  MemberTag.swift
//  CoreUIComponents
//
//  Created by euijjang97 on 11/1/26.
//

import CoreDesignSystem
import SwiftUI
import UMCFoundation

/// Figma Tag/Part와 Tag/Role의 공용 표시 컴포넌트. 모바일 기본값은 Sm이다.
public struct MemberTag: View {

    // MARK: - Type

    public enum Size {
        case small, medium, large

        var fontSize: CGFloat {
            switch self {
            case .small: 12
            case .medium: 14
            case .large: 18
            }
        }

        var height: CGFloat {
            switch self {
            case .small: 22
            case .medium: 26
            case .large: 32
            }
        }

        var padding: CGFloat {
            switch self {
            case .small: 6
            case .medium: 7
            case .large: 8
            }
        }
    }

    public enum Style {
        case filled, outlined
    }

    // MARK: - Property

    private let title: String
    private let foreground: Color
    private let background: Color
    private let border: Color
    private let size: Size

    // MARK: - Init

    public init(part: UMCPartType, style: Style = .filled, size: Size = .small) {
        let palette = part.tagPalette
        title = part.name
        foreground = style == .filled ? .tagText : palette.text
        background = style == .filled ? palette.fill : palette.outlinedFill
        border = style == .filled ? .clear : palette.fill
        self.size = size
    }

    public init(role: ManagementTeam, size: Size = .small) {
        title = role.tagName
        foreground = role.textColor
        background = role.backgroundColor
        border = .clear
        self.size = size
    }

    /// 서버 역할과 별개인 Product 팀 표시용 태그.
    public static func product(size: Size = .small) -> MemberTag {
        MemberTag(
            title: "⚙ Product", foreground: .tagRoleProductText,
            background: .tagRoleProductBackground, size: size
        )
    }

    private init(title: String, foreground: Color, background: Color, size: Size) {
        self.title = title
        self.foreground = foreground
        self.background = background
        self.border = .clear
        self.size = size
    }

    // MARK: - Body

    public var body: some View {
        Text(title)
            .font(.custom(AppFontWeight.medium.fontName, size: size.fontSize, relativeTo: .caption))
            .foregroundStyle(foreground)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, size.padding)
            .padding(.vertical, 3)
            .frame(minHeight: size.height)
            .background(background, in: .rect(cornerRadius: size == .large ? 8 : 6))
            .overlay {
                RoundedRectangle(cornerRadius: size == .large ? 8 : 6)
                    .strokeBorder(border, lineWidth: 1)
            }
            .shadow(color: .tagShadow.opacity(0.5), radius: 8, y: 4)
    }
}

extension UMCPartType {
    /// 디자인에 없는 구 기수 파트는 이름과 기존 시드 팔레트를 보존한다.
    var tagPalette: (fill: Color, outlinedFill: Color, text: Color) {
        switch self {
        case .pm:
            (.tagPartPMBackground, .tagPartPMOutlinedBackground, .tagPartPMText)
        case .design:
            (.tagPartDesignBackground, .tagPartDesignOutlinedBackground, .tagPartDesignText)
        case .webProductEngineer:
            (.tagPartWebPEBackground, .tagPartWebPEOutlinedBackground, .tagPartWebPEText)
        case .mobileProductEngineer:
            (.tagPartMobilePEBackground, .tagPartMobilePEOutlinedBackground, .tagPartMobilePEText)
        default:
            (chipSeedColor, chipSeedColor, .black)
        }
    }
}
