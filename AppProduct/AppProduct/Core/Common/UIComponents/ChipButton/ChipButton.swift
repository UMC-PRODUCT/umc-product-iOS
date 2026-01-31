//
//  ChipButton.swift
//  AppProduct
//
//  Created by 이예지 on 1/3/26.
//

import SwiftUI

// MARK: - ChipButton

/// 선택 가능한 칩 형태의 버튼 컴포넌트
///
/// 필터, 카테고리 선택 등에 사용되는 캡슐 모양의 버튼입니다.
/// Environment를 통해 크기와 스타일을 커스터마이징할 수 있습니다.
struct ChipButton: View {

    // MARK: - Properties

    /// 버튼에 표시될 텍스트
    private let title: String

    /// 선택 상태 여부 (선택 시 스타일 변경)
    private let isSelected: Bool

    /// 우측에 chevron 아이콘 표시 여부
    private let trailingIcon: Bool?

    /// 버튼 탭 시 실행될 액션
    private let action: () -> Void

    /// Environment로 주입되는 버튼 크기 스타일
    @Environment(\.chipButtonSize) private var size

    /// Environment로 주입되는 버튼 컬러 스타일
    @Environment(\.chipButtonStyle) private var style

    // MARK: - Initializer

    /// ChipButton 생성자
    ///
    /// - Parameters:
    ///   - title: 버튼 텍스트
    ///   - isSelected: 선택 상태 여부
    ///   - trailingIcon: chevron 아이콘 표시 여부 (기본값: nil)
    ///   - action: 버튼 탭 액션
    init(_ title: String, isSelected: Bool, trailingIcon: Bool? = nil, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.trailingIcon = trailingIcon
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            ChipButtonContent(
                title: title,
                size: size,
                style: style,
                isSelected: isSelected,
                trailingIcon: trailingIcon
            )
            .equatable()
        }
    }
}

// MARK: - ChipButtonContent (Presenter)

/// ChipButton의 Presenter 컴포넌트
///
/// Container-Presenter 패턴을 적용하여 렌더링 성능을 최적화합니다.
/// Equatable 구현으로 불필요한 재렌더링을 방지합니다.
private struct ChipButtonContent: View, Equatable {

    // MARK: - Property

    /// 버튼 텍스트
    let title: String

    /// 버튼 크기 스타일
    let size: ChipButtonSize

    /// 버튼 컬러 스타일
    let style: ChipButtonStyle

    /// 선택 상태 여부
    let isSelected: Bool

    /// chevron 아이콘 표시 여부
    let trailingIcon: Bool?

    // MARK: - Constant

    fileprivate enum Constants {
        /// chevron 아이콘 크기
        static let chevronSize: CGFloat = 10

        /// 버튼 상하 패딩
        static let btnVerticalPadding: CGFloat = 8
    }

    // MARK: - Equatable

    /// Equatable 비교 구현
    ///
    /// trailingIcon은 클로저가 아니므로 비교에 포함됩니다.
    static func == (lhs: ChipButtonContent, rhs: ChipButtonContent) -> Bool {
        lhs.title == rhs.title &&
        lhs.size == rhs.size &&
        lhs.style == rhs.style &&
        lhs.isSelected == rhs.isSelected &&
        lhs.trailingIcon == rhs.trailingIcon
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: DefaultSpacing.spacing4) {
            Text(title)
            // 드롭다운 표시용 chevron 아이콘
            if trailingIcon != nil && trailingIcon == true {
                Image(systemName: "chevron.down")
                    .font(.system(size: Constants.chevronSize))
            }
        }
        .foregroundStyle(style.textColor(isSelected: isSelected))
        .font(size.font)
        .padding(.horizontal, size.horizonPadding)
        .padding(.vertical, Constants.btnVerticalPadding)
        .background(
            Capsule()
                .fill(style.bgColor(isSelected: isSelected))
        )
        .glassEffect(.clear.interactive(), in: Capsule())
    }
}

// MARK: - ChipButton + AnyChipButton

extension ChipButton: AnyChipButton {}
