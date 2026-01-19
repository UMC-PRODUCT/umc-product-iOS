//
//  ToolBarCollection.swift
//  AppProduct
//
//  Created by euijjang97 on 1/13/26.
//

import Foundation
import SwiftUI

struct ToolBarCollection {
    
    /// 일정 추가 버튼
    struct AddBtn: ToolbarContent {
        let action: () -> Void
        var tintColor: Color = .grey900
        
        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarTrailing, content: {
                Button(action: { action() }, label: {
                    Image(systemName: "magnifyingglass")
                })
                .tint(tintColor)
            })
        }
    }
    
    /// 상단 알림 히스토리 버튼
    struct BellBtn: ToolbarContent {
        let action: () -> Void
        var tintColor: Color = .grey900
        let recentPush: Bool = false
        
        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarTrailing, content: {
                Button(action: { action() }, label: {
                    Image(systemName: recentPush ? "bell.badge" : "bell")
                })
                .tint(tintColor)
            })
        }
    }
    
    /// 상단 로고 툴바
    struct Logo: ToolbarContent {
        let image: ImageResource
        let action: () -> Void
        
        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarLeading, content: {
                Button(action: {
                    action()
                }, label: {
                    Image(image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 40)
                        .padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
                })
            })
        }
    }
}
