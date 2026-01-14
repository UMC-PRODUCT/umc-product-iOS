//
//  DefaultConstant.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import Foundation

/// 전역적으로 사용하는 레이아웃 상수 관리.
///
/// 앱 전체에서 일관된 간격, 패딩, 모서리 반경 등을 적용하기 위한 상수 모음입니다.
enum DefaultConstant {
    /// 화면 좌우 여백.
    static let defaultSafeHorizon: CGFloat = 16

    /// 하단 Safe Area 여백 (탭바, 플로팅 버튼 등을 고려한 높이).
    static let defaultSafeBottom: CGFloat = 56

    /// 컴포넌트 간 수직 간격.
    static let defaultCapsuleSpacing: CGFloat = 28

    /// Safe Area를 고려한 버튼 패딩.
    static let defaultSafeBtnPadding: CGFloat = 10

    /// 카드, 버튼 등의 기본 모서리 둥글기.
    static let defaultCornerRadius: CGFloat = 20

    /// 콘텐츠 영역 하단 마진.
    static let defaultContentBottomMargins: CGFloat = 40

    /// 콘텐츠 영역 상단 마진.
    static let defaultContentTopMargins: CGFloat = 20

    /// 버튼 내부 패딩.
    static let defaultBtnPadding: CGFloat = 10

    /// 텍스트 필드 내부 패딩.
    static let defaultTextFieldPadding: CGFloat = 14

    /// 상단 캡슐 컴포넌트 간격 (헤더 영역 등).
    static let defaultTopCapsuleSpacing: CGFloat = 10

    /// 기본 애니메이션 지속 시간 (초).
    static let animationTime: TimeInterval = 0.3

    /// 텍스트 줄 간격.
    static let lineSpacing: CGFloat = 2.5
}
