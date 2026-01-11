//
//  NoticeChip.swift
//  AppProduct
//
//  Created by 이예지 on 1/10/26.
//

import SwiftUI

// MARK: - NoticeChip
/// 공지 화면: 공지 상세화면 공지 구분 칩
struct NoticeChip: View {
    
    // MARK: - Property
    let noticeType: NoticeType
    
    // MARK: - Body
    var body: some View {
        Text(noticeType.rawValue)
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
        NoticeChip(noticeType: .core)
        NoticeChip(noticeType: .branch)
        NoticeChip(noticeType: .campus)
        NoticeChip(noticeType: .part)
        NoticeChip(noticeType: .essential)
    }
}
