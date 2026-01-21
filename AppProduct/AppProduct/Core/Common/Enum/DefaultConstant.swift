//
//  DefaultConstant.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import Foundation
import SwiftUI

/// 전역적으로 사용하는 Spacing 상수 관리
enum DefaultConstant {
    static let defaultSafeHorizon: CGFloat = 16
    static let defaultSafeBottom: CGFloat = 56
    static let defaultCapsuleSpacing: CGFloat = 12
    static let defaultSafeBtnPadding: CGFloat = 10
    static let defaultCornerRadius: CGFloat = 40
    static let defaultContentBottomMargins: CGFloat = 40
    static let defaultContentTopMargins: CGFloat = 20
    static let defaultBtnPadding: CGFloat = 10
    static let defaultTextFieldPadding: CGFloat = 14
    static let defaultTopCapsuleSpacing: CGFloat = 10
    static let defaultListPadding: EdgeInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
    
    static let animationTime: TimeInterval = 0.3
    static let lineSpacing: CGFloat = 2.5
}
