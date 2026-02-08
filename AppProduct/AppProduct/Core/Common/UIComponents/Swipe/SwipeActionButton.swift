//
//  SwipeActionButton.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/8/26.
//

import SwiftUI

/// 스와이프 액션 버튼 컴포넌트
///
/// 스와이프 제스처로 나타나는 액션 버튼을 정의합니다.
///
/// ```swift
/// SwipeActionButton(
///     icon: "star.fill",
///     title: "베스트",
///     color: .orange
/// ) {
///     // 액션 처리
/// }
/// ```
struct SwipeActionButton: View {

    // MARK: - Property

    /// SF Symbol 아이콘 이름
    private let icon: String

    /// 버튼 텍스트
    private let title: String

    /// 배경색
    private let color: Color

    /// 탭 액션
    private let action: () -> Void

    // MARK: - Initializer

    /// SwipeActionButton 생성자
    /// - Parameters:
    ///   - icon: SF Symbol 아이콘 이름
    ///   - title: 버튼 텍스트
    ///   - color: 배경색
    ///   - action: 탭 액션 클로저
    init(
        icon: String,
        title: String,
        color: Color,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.color = color
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            VStack(spacing: Constants.iconTextSpacing) {
                // 원형 아이콘 배경
                Circle()
                    .fill(color)
                    .frame(width: Constants.circleSize, height: Constants.circleSize)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: Constants.iconSize, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                // 텍스트 라벨
                Text(title)
                    .font(.system(size: Constants.fontSize, weight: .medium))
                    .foregroundStyle(color)
            }
            .frame(width: Constants.buttonWidth)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Constants

extension SwipeActionButton {

    /// SwipeActionButton 상수
    private enum Constants {
        /// 원형 배경 크기
        static let circleSize: CGFloat = 56

        /// 아이콘 크기
        static let iconSize: CGFloat = 24

        /// 폰트 크기
        static let fontSize: CGFloat = 12

        /// 아이콘-텍스트 간격
        static let iconTextSpacing: CGFloat = 6

        /// 버튼 전체 너비
        static let buttonWidth: CGFloat = 72
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Swipe Actions") {
    VStack(spacing: 20) {
        // 단일 버튼 프리뷰
        SwipeActionButton(icon: "star.fill", title: "베스트", color: .orange) {
            print("베스트 액션")
        }
        .frame(height: 100)

        // 여러 버튼 나란히
        HStack(spacing: 12) {
            SwipeActionButton(icon: "star.fill", title: "베스트", color: .orange) {
                print("베스트 액션")
            }

            SwipeActionButton(icon: "checkmark.circle.fill", title: "검토", color: .indigo) {
                print("검토 액션")
            }

            SwipeActionButton(icon: "trash.fill", title: "삭제", color: .red) {
                print("삭제 액션")
            }
        }
        .frame(height: 100)
    }
    .padding()
}
#endif
