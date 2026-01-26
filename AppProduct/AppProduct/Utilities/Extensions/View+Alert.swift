//
//  View+Alert.swift
//  AppProduct
//
//  Created by euijjang97 on 1/25/26.
//

import Foundation
import SwiftUI

extension View {
    /// 커스텀 알림 프롬프트를 표시하는 View Modifier
    ///
    /// `AlertPrompt` 상태를 바인딩하여 시스템 알림창을 표시합니다.
    /// 긍정/부정 버튼의 제목과 액션을 설정할 수 있으며, 긍정 버튼은 파괴적(destructive) 스타일을 지원합니다.
    ///
    /// - Parameter item: 알림창을 제어할 `AlertPrompt` 데이터 바인딩
    /// - Returns: 알림이 적용된 View
    func alertPrompt(item: Binding<AlertPrompt?>) -> some View {
        self.alert(
            item.wrappedValue?.title ?? "",
            isPresented: Binding(
                get: { item.wrappedValue != nil },
                set: { if !$0 { item.wrappedValue = nil } }
            ),
            presenting: item.wrappedValue
        ) { alert in
            if let positiveBtnTitle = alert.positiveBtnTitle {
                Button(
                    positiveBtnTitle,
                    role: alert.isPositiveBtnDestructive ? .destructive : nil
                ) {
                    alert.positiveBtnAction?()
                }
            }
            
            if let negativeBtnTitle = alert.negativeBtnTitle {
                Button(negativeBtnTitle, role: .cancel) {
                    alert.negativeBtnAction?()
                }
            }
        } message: { alert in
            Text(alert.message)
        }
    }
}
