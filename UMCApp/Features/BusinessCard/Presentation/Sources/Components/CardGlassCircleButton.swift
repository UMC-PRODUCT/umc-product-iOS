//
//  CardGlassCircleButton.swift
//  BusinessCardPresentation
//
//  Created by euijjang97 on 8/31/26.
//

import CoreDesignSystem
import SwiftUI

/// 명함 카드 위에 얹는 원형 글래스 아이콘 버튼.
///
/// ``BusinessCardFaceView`` 의 플립 버튼이 쓴다. 반경·지름을 고칠 자리를 하나로 둔다.
///
/// 시각 지름은 시안값 32pt 로 두고 **히트 영역만 HIG 44pt** 로 넓힌다 — 카드 모서리에
/// 붙는 32pt 히트 영역은 오탭을 부른다.
struct CardGlassCircleButton: View {

    // MARK: - Property

    private let systemName: String
    private let label: String
    private let action: () -> Void

    private enum Metrics {
        /// 시안 실측 지름·아이콘 크기 (`Figma 12639:33234` 플립 버튼).
        static let diameter: CGFloat = 32
        static let iconSize: CGFloat = 15
    }

    // MARK: - Init

    init(
        systemName: String,
        label: String,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.label = label
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: Metrics.iconSize))
                .foregroundStyle(Color.white)
                .frame(minWidth: Metrics.diameter, minHeight: Metrics.diameter)
                .glassEffect(.clear, in: Circle())
                .frame(
                    minWidth: DefaultConstant.minimumTouchTarget,
                    minHeight: DefaultConstant.minimumTouchTarget
                )
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
    }
}
