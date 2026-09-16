//
//  AppleIntelligenceStyle.swift
//  CoreDesignSystem
//
//  Created by euijjang97 on 9/16/26.
//

import SwiftUI

// MARK: - Apple Intelligence

public extension ShapeStyle where Self == LinearGradient {

    /// Apple Intelligence 진입점을 표시하는 브랜드 그라디언트.
    ///
    /// 앱 팔레트(`indigo*`)가 아니라 Apple 워드마크 색이라 `Color+Tokens` 의 색 토큰으로
    /// 올리지 않고 여기에 가둔다. 온디바이스 AI 기능임을 알리는 자리에서만 쓴다 —
    /// 일반 액션 아이콘에 쓰면 이 신호가 무의미해진다.
    ///
    /// 라이트·다크 모두 같은 값을 쓴다. Apple 워드마크 자체가 외관에 따라 색을 바꾸지 않고,
    /// 네 스톱 모두 채도가 높아 양쪽 배경에서 모두 떠오른다. 다만 아이콘 단독으로 의미를
    /// 지지 않게 항상 라벨과 함께 둔다.
    ///
    /// - Note: 정확한 hex 는 **디자인팀 확인 필요**. 현재 값은 Apple Intelligence 워드마크에서
    ///   뽑은 근사치로, `ThreadClassificationCard` 가 쓰던 값을 그대로 옮겼다.
    static var appleIntelligence: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.176, blue: 0.333),     // 핑크
                Color(red: 0.796, green: 0.188, blue: 0.878),   // 퍼플
                Color(red: 0.0, green: 0.753, blue: 0.910),     // 블루
                Color(red: 1.0, green: 0.553, blue: 0.157)      // 오렌지
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
