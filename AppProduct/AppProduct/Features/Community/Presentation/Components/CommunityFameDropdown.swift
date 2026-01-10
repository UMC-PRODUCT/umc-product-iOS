//
//  CommunityFameDropdown.swift
//  AppProduct
//
//  Created by 이예지 on 1/10/26.
//

import SwiftUI

struct CommunityFameDropdown: ViewModifier {
    
    let category: String
    
    init(category: String) {
        self.category = "전체"
    }
    
    func body(content: Content) -> some View {
        content
            .overlay {
                HStack(spacing: 34) {
                    Text(category)
                        .font(.app(.caption1, weight: .regular))
                    
                    Image(systemName: "chevron.down")
                        .resizable()
                        .frame(width: 8, height: 4)
                        .foregroundStyle(Color.neutral500)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundStyle(Color.background)
                }
            }
    }
}
