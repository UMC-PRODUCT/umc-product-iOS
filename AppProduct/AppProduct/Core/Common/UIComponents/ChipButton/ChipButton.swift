//
//  ChipButton.swift
//  AppProduct
//
//  Created by 이예지 on 1/3/26.
//

import SwiftUI

// MARK: - ChipButton

/// 선택 상태를 표시하는 칩 형태의 버튼 컴포넌트
///
/// 필터링, 카테고리 선택, 태그 표시 등에 사용합니다.
/// `action`이 nil이면 인터랙션 없는 읽기 전용 태그로 동작합니다.
///
/// ## 사용 예시
///
/// **기본 사용 (인터랙티브 버튼)**
/// ```swift
/// ChipButton("iOS", isSelected: selected) {
///     selected.toggle()
/// }
/// .buttonSize(.medium)
/// .buttonStyle(.filter)
/// ```
///
/// **아이콘 포함**
/// ```swift
/// // Leading 아이콘 (SF Symbol)
/// ChipButton("링크", isSelected: true, leadingIcon: "link") { }
///
/// // Trailing chevron (드롭다운 표시용)
/// ChipButton("전체", isSelected: false, trailingIcon: true) { }
/// ```
///
/// **읽기 전용 태그 (action 생략)**
/// ```swift
/// ChipButton("Week 1", isSelected: false)
/// ```
///
/// ## 사이즈 옵션 (`buttonSize`)
///
/// | Size | Font | Padding | 용도 |
/// |------|------|---------|------|
/// | `.small` | footnote | 8pt | 컴팩트한 태그, 뱃지 |
/// | `.medium` | subheadline | 16pt | 일반 필터, 선택 버튼 |
/// | `.large` | callout | 16pt | 강조 버튼 |
///
/// ## 스타일 옵션 (`buttonStyle`)
///
/// | Style | 선택 시 | 미선택 시 | 용도 |
/// |-------|--------|----------|------|
/// | `.filter` | indigo500/grey000 | grey200/grey600 | 공지 리스트 필터 |
/// | `.board` | indigo500/grey000 | grey300/grey000 | 게시판 분류 선택 |
/// | `.fame` | yellow500/white | white/grey600 | 명예의전당 주차 선택 |
///
/// - Important: `buttonSize()`와 `buttonStyle()`은 반드시 ChipButton에 직접 적용해야 합니다.
///   다른 컨테이너 뷰에 적용하면 Environment 전파가 되지 않습니다.
///
/// - Note: Liquid Glass 효과가 자동 적용됩니다.
///   인터랙티브 버튼은 `.interactive()`, 읽기 전용은 `.identity` 사용.
struct ChipButton: View {
    // MARK: - Properties

    private let title: String
    private let isSelected: Bool
    private let leadingIcon: String?
    private let trailingIcon: Bool?
    private let action: (() -> Void)?

    @Environment(\.chipButtonSize) private var size
    @Environment(\.chipButtonStyle) private var style

    // MARK: - Initializer

    /// ChipButton 생성자
    /// - Parameters:
    ///   - title: 버튼 텍스트
    ///   - isSelected: 선택 상태
    ///   - trailingIcon: 트레일링 아이콘 표시 여부
    ///   - action: 탭 액션 (nil이면 읽기 전용 태그로 동작)
    init(
        _ title: String,
        isSelected: Bool,
        leadingIcon: String? = nil,
        trailingIcon: Bool? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.isSelected = isSelected
        self.leadingIcon = leadingIcon
        self.trailingIcon = trailingIcon
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        if let action = action {
            Button(action: action) {
                ChipButtonContent(
                    title: title,
                    size: size,
                    style: style,
                    isSelected: isSelected,
                    leadingIcon: leadingIcon,
                    trailingIcon: trailingIcon,
                    isInteractive: true
                )
                .equatable()
            }
        } else {
            ChipButtonContent(
                title: title,
                size: size,
                style: style,
                isSelected: isSelected,
                leadingIcon: leadingIcon,
                trailingIcon: trailingIcon,
                isInteractive: false
            )
            .equatable()
        }
    }
}

// MARK: - ChipButtonContent (Presenter)

private struct ChipButtonContent: View, Equatable {
    let title: String
    let size: ChipButtonSize
    let style: ChipButtonStyle
    let isSelected: Bool
    let leadingIcon: String?
    let trailingIcon: Bool?
    let isInteractive: Bool
    
    // MARK: - Constant
    fileprivate enum Constants {
        static let chevronSize: CGFloat = 10
        static let btnVerticalPadding: CGFloat = 8
    }
    
    static func == (lhs: ChipButtonContent, rhs: ChipButtonContent) -> Bool {
        lhs.title == rhs.title &&
        lhs.size == rhs.size &&
        lhs.style == rhs.style &&
        lhs.isSelected == rhs.isSelected &&
        lhs.leadingIcon == rhs.leadingIcon &&
        lhs.trailingIcon == rhs.trailingIcon &&
        lhs.isInteractive == rhs.isInteractive
    }

    var body: some View {
        HStack(spacing: DefaultSpacing.spacing4) {
            Text(title)
            if trailingIcon == true {
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
        .glassEffect(
            isInteractive ? .clear.interactive() : .identity,
            in: Capsule()
        )
    }
}

// MARK: - ChipButton + AnyChipButton

extension ChipButton: AnyChipButton {}
