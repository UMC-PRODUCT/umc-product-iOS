//
//  ColorTokens.swift
//  AppProduct
//
//  Created by jaewon Lee on 2026-01-01.
//

import SwiftUI

// MARK: - Color Extension

extension Color {

    // MARK: - Primary (Indigo)

    /// #F5F7FF
    static let primary100 = Color("Primary100", bundle: .main)
    /// #D6DEFF
    static let primary200 = Color("Primary200", bundle: .main)
    /// #B4C1FF
    static let primary300 = Color("Primary300", bundle: .main)
    /// #7E96FF
    static let primary400 = Color("Primary400", bundle: .main)
    /// #4869F0 - Main Primary
    static let primary500 = Color("Primary500", bundle: .main)
    /// #3F5DDA
    static let primary600 = Color("Primary600", bundle: .main)
    /// #344EC0
    static let primary700 = Color("Primary700", bundle: .main)
    /// #2A3E99
    static let primary800 = Color("Primary800", bundle: .main)
    /// #1F2F73
    static let primary900 = Color("Primary900", bundle: .main)

    // MARK: - Accent (Orange)

    /// #FFF3EB
    static let accent100 = Color("Accent100", bundle: .main)
    /// #FFDAC2
    static let accent200 = Color("Accent200", bundle: .main)
    /// #FFBE94
    static let accent300 = Color("Accent300", bundle: .main)
    /// #FF9F61
    static let accent400 = Color("Accent400", bundle: .main)
    /// #FF7F2D
    static let accent500 = Color("Accent500", bundle: .main)
    /// #FF6D0F - Main Accent
    static let accent600 = Color("Accent600", bundle: .main)
    /// #F05E00
    static let accent700 = Color("Accent700", bundle: .main)
    /// #D65400
    static let accent800 = Color("Accent800", bundle: .main)
    /// #C24C00
    static let accent900 = Color("Accent900", bundle: .main)

    // MARK: - Neutral (Grey)

    /// #FFFFFF
    static let neutral000 = Color("Neutral000", bundle: .main)
    /// #F4F5F7
    static let neutral100 = Color("Neutral100", bundle: .main)
    /// #E7E8EA
    static let neutral200 = Color("Neutral200", bundle: .main)
    /// #CDD1D5
    static let neutral300 = Color("Neutral300", bundle: .main)
    /// #B2B8BF
    static let neutral400 = Color("Neutral400", bundle: .main)
    /// #8A949E
    static let neutral500 = Color("Neutral500", bundle: .main)
    /// #6D7882
    static let neutral600 = Color("Neutral600", bundle: .main)
    /// #464C54
    static let neutral700 = Color("Neutral700", bundle: .main)
    /// #34363E
    static let neutral800 = Color("Neutral800", bundle: .main)
    /// #1F2124
    static let neutral900 = Color("Neutral900", bundle: .main)

    // MARK: - Status: Success (Green)

    /// #DDF8EF
    static let success100 = Color("Success100", bundle: .main)
    /// #8FE0C8
    static let success300 = Color("Success300", bundle: .main)
    /// #0CA678 - Main Success
    static let success500 = Color("Success500", bundle: .main)
    /// #087C5B
    static let success700 = Color("Success700", bundle: .main)
    /// #055741
    static let success900 = Color("Success900", bundle: .main)

    // MARK: - Status: Warning (Yellow)

    /// #FFF7D1
    static let warning100 = Color("Warning100", bundle: .main)
    /// #FFD180
    static let warning300 = Color("Warning300", bundle: .main)
    /// #FFA500 - Main Warning
    static let warning500 = Color("Warning500", bundle: .main)
    /// #C97F00
    static let warning700 = Color("Warning700", bundle: .main)
    /// #A36800
    static let warning900 = Color("Warning900", bundle: .main)

    // MARK: - Status: Danger (Red)

    /// #FDECEC
    static let danger100 = Color("Danger100", bundle: .main)
    /// #F29B9B
    static let danger300 = Color("Danger300", bundle: .main)
    /// #E03131 - Main Danger
    static let danger500 = Color("Danger500", bundle: .main)
    /// #A82424
    static let danger700 = Color("Danger700", bundle: .main)
    /// #751A1A
    static let danger900 = Color("Danger900", bundle: .main)

    // MARK: - Semantic Colors

    /// Background color - Light: #F4F5F7, Dark: #000000
    static let background = Color("Background", bundle: .main)
    /// Border color - #CDD1D5
    static let border = Color("Border", bundle: .main)
    /// Primary text color - Light: #34363E, Dark: #FFFFFF
    static let textPrimary = Color("TextPrimary", bundle: .main)
    /// Secondary text color - #6D7882
    static let textSecondary = Color("TextSecondary", bundle: .main)
    /// Placeholder text color - #B2B8BF
    static let placeholder = Color("Placeholder", bundle: .main)
}

// MARK: - Convenience Aliases

extension Color {
    /// Primary main color (Primary500)
    static let primaryMain = Color.primary500
    /// Accent main color (Accent600)
    static let accentMain = Color.accent600
    /// Success main color (Success500)
    static let successMain = Color.success500
    /// Warning main color (Warning500)
    static let warningMain = Color.warning500
    /// Danger main color (Danger500)
    static let dangerMain = Color.danger500
}
