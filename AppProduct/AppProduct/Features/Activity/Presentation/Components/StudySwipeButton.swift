//
//  StudySwipeButton.swift
//  AppProduct
//
//  Created by 이예지 on 1/9/26.
//

import SwiftUI

// MARK: - StudySwipeButton
/// 왼쪽 스와이프 시 보이는 버튼(베스트, 검토)
struct StudySwipeButton: View, Equatable {
    
    let swipeButtonType: SwipeButtonType
    
    enum SwipeButtonType: String {
        case best = "베스트"
        case review = "검토"
        
        var icon: Image {
            switch self {
            case .best:
                return Image(systemName: "gift")
            case .review:
                return Image(systemName: "checkmark.circle")
            }
        }
        
        var color: Color {
            switch self {
            case .best:
                return .yellow700
            case .review:
                return .green900
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 5) {
            swipeButtonType.icon
                .resizable()
                .frame(width: 17, height: 17)
            
            Text(swipeButtonType.rawValue)
                .font(.app(.caption1, weight: .bold))
        }
        .foregroundStyle(swipeButtonType.color)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    HStack {
        StudySwipeButton(swipeButtonType: .best)
        
        StudySwipeButton(swipeButtonType: .review)
    }
}
