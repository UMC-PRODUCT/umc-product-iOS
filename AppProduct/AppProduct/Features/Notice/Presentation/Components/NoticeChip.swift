//
//  NoticeChip.swift
//  AppProduct
//
//  Created by 이예지 on 1/10/26.
//

import SwiftUI

// MARK: - NoticeChip
struct NoticeChip: View {
    
    // MARK: - Property
    let text: String
    let noticeType: NoticeType
    
    // MARK: - Body
    var body: some View {
        Text(text)
            .font(.app(.caption1, weight: .regular))
            .foregroundStyle(noticeType.textColor)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(noticeType.backgroundColor)
            }
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    HStack {
        NoticeChip(text: "중앙", noticeType: .target)
        
        NoticeChip(text: "필독", noticeType: .essential)
    }
}
