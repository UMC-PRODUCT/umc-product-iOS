//
//  DefaultConstant.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import Foundation
import SwiftUI

/// 전역적으로 사용하는 레이아웃 상수 관리.
///
/// 앱 전체에서 일관된 간격, 패딩, 모서리 반경 등을 적용하기 위한 상수 모음입니다.
enum DefaultConstant {
    /// 아이콘 사이즈
    static let iconSize: CGFloat = 36
    
    /// 아이콘 모서리 둥글기
    static let cornerRadius: CGFloat = 24
    
    /// 아이콘 패딩
    static let iconPadding: CGFloat = 8
    
    /// 화면 좌우 여백.
    static let defaultSafeHorizon: CGFloat = 16
    
    static let defaultSafeTop: CGFloat = 20

    /// 하단 Safe Area 여백 (탭바, 플로팅 버튼 등을 고려한 높이).
    static let defaultSafeBottom: CGFloat = 56

    /// 컴포넌트 간 수직 간격.
    static let defaultCapsuleSpacing: CGFloat = 28

    /// Safe Area를 고려한 버튼 패딩.
    static let defaultSafeBtnPadding: CGFloat = 10

    /// 카드, 버튼 등의 기본 모서리 둥글기.
    static let defaultCornerRadius: CGFloat = 30
    
    /// 리스트 카드의 기본 모서리 둥글기.
    static let concentricRadius: Edge.Corner.Style = 40

    /// 콘텐츠 영역 하단 마진.
    static let defaultContentBottomMargins: CGFloat = 40

    /// 콘텐츠 영역 상단 마진.
    static let defaultContentTopMargins: CGFloat = 20
    
    static let defaultContentTrailingMargins: CGFloat = 4

    /// 버튼 내부 패딩.
    static let defaultBtnPadding: CGFloat = 10
    
    /// ToolBarTitle 버튼 패딩
    static let defaultToolBarTitlePadding: EdgeInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)

    /// 텍스트 필드 내부 패딩.
    static let defaultTextFieldPadding: CGFloat = 14

    /// 상단 캡슐 컴포넌트 간격 (헤더 영역 등).
    static let defaultTopCapsuleSpacing: CGFloat = 10

    /// 리스트 카드 기본 패딩.
    static let defaultListPadding: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
    
    /// 카드 기본 패딩.
    static let defaultCardPadding: EdgeInsets = .init(top: 24, leading: 16, bottom: 24, trailing: 16)
    
    /// 기본 애니메이션 지속 시간 (초).
    static let animationTime: TimeInterval = 0.3
    
    static let transitionScale: CGFloat = 0.95

    /// 텍스트 줄 간격.
    static let lineSpacing: CGFloat = 2.5

    /// 뱃지 패딩.
    static let badgePadding: EdgeInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
}

// MARK: System Image Constants

extension DefaultConstant {
    /// 화살표 아이콘 이미지 이름
    static let chevronForwardImage: String = "chevron.forward"

    /// 상향 화살표 아이콘
    static let chevronUpImage: String = "chevron.up"

    /// 하향 화살표 아이콘
    static let chevronDownImage: String = "chevron.down"
}
